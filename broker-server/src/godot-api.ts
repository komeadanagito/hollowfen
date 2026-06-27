import express, { type Request, type Response } from 'express'
import { ExecutorManager } from './executor-manager.js'
import { resolveExecutor } from './executor-selection.js'
import { TcpServer } from './tcp-server.js'
import type { ApiResponse, ExecuteResult } from './types.js'

const DEFAULT_TREE_DEPTH = 4
const MAX_TIMEOUT_MS = 300000

type JsonObject = Record<string, unknown>

export function createGodotRouter(executorManager: ExecutorManager, tcpServer: TcpServer) {
	const router = express.Router()

	router.post('/tree', async (req: Request, res: Response) => {
		const body = bodyObject(req.body)
		const maxDepth = normalizeMaxDepth(body.max_depth)
		if (typeof maxDepth === 'string') {
			res.status(400).json({ success: false, error: maxDepth } satisfies ApiResponse)
			return
		}

		await executeGodotOperation(req, res, executorManager, tcpServer, buildTreeScript({
			nodePath: optionalString(body.node_path) || '.',
			maxDepth,
		}))
	})

	router.post('/node/get', async (req: Request, res: Response) => {
		const body = bodyObject(req.body)
		const required = requireString(body, 'node_path') || requireString(body, 'property')
		if (required) {
			res.status(400).json(required satisfies ApiResponse)
			return
		}

		await executeGodotOperation(req, res, executorManager, tcpServer, buildGetScript({
			nodePath: body.node_path as string,
			property: body.property as string,
		}))
	})

	router.post('/node/set', async (req: Request, res: Response) => {
		const body = bodyObject(req.body)
		const required = requireString(body, 'node_path') || requireString(body, 'property')
		if (required) {
			res.status(400).json(required satisfies ApiResponse)
			return
		}
		if (!Object.prototype.hasOwnProperty.call(body, 'value')) {
			res.status(400).json({ success: false, error: 'Missing required field: value' } satisfies ApiResponse)
			return
		}

		try {
			await executeGodotOperation(req, res, executorManager, tcpServer, buildSetScript({
				nodePath: body.node_path as string,
				property: body.property as string,
				value: body.value,
			}))
		} catch (err: unknown) {
			res.status(400).json({ success: false, error: (err as Error).message } satisfies ApiResponse)
		}
	})

	router.post('/node/call', async (req: Request, res: Response) => {
		const body = bodyObject(req.body)
		const required = requireString(body, 'node_path') || requireString(body, 'method')
		if (required) {
			res.status(400).json(required satisfies ApiResponse)
			return
		}
		if (body.args !== undefined && !Array.isArray(body.args)) {
			res.status(400).json({ success: false, error: 'Field args must be an array when provided' } satisfies ApiResponse)
			return
		}

		try {
			await executeGodotOperation(req, res, executorManager, tcpServer, buildCallScript({
				nodePath: body.node_path as string,
				method: body.method as string,
				args: (body.args as unknown[] | undefined) || [],
			}))
		} catch (err: unknown) {
			res.status(400).json({ success: false, error: (err as Error).message } satisfies ApiResponse)
		}
	})

	return router
}

async function executeGodotOperation(
	req: Request,
	res: Response,
	executorManager: ExecutorManager,
	tcpServer: TcpServer,
	code: string,
): Promise<void> {
	const body = bodyObject(req.body)
	const timeout = normalizeTimeoutMs(body.timeout_ms)
	if (typeof timeout === 'string') {
		res.status(400).json({ success: false, error: timeout } satisfies ApiResponse)
		return
	}

	const selection = resolveExecutor(executorManager, body)
	if (!selection.executor) {
		res.status(selection.status || 404).json({
			success: false,
			error: selection.error,
			hint: selection.hint,
		} satisfies ApiResponse)
		return
	}

	try {
		const execution = await tcpServer.sendExecute(selection.executor.id, code, 'gdscript', timeout)
		respondWithExecution(res, execution)
	} catch (err: unknown) {
		const error = err as Error
		if (error.message === 'TIMEOUT') {
			res.status(504).json({
				success: false,
				error: 'Executor execution timed out',
				hint: 'Increase timeout_ms or simplify the Godot operation.',
			} satisfies ApiResponse)
		} else {
			res.status(500).json({
				success: false,
				error: error.message || 'Execution failed',
			} satisfies ApiResponse)
		}
	}
}

function respondWithExecution(res: Response, execution: ExecuteResult): void {
	if (!execution.compile_success || !execution.run_success) {
		res.status(502).json({
			success: false,
			error: execution.compile_error || execution.run_error || 'Godot execution failed',
			data: { execution },
		} satisfies ApiResponse)
		return
	}

	res.json({
		success: true,
		data: {
			result: parseOutputData(execution),
			execution,
		},
	} satisfies ApiResponse)
}

function parseOutputData(execution: ExecuteResult): unknown {
	const entry = execution.outputs.find(([key]) => key === 'data')
	if (!entry) return null
	try {
		return JSON.parse(entry[1])
	} catch {
		return entry[1]
	}
}

function buildTreeScript({ nodePath, maxDepth }: { nodePath: string; maxDepth: number }): string {
	return `${commonGodotHelpers()}

func _hastur_collect_tree(node: Node, root: Node, depth: int, max_depth: int) -> Dictionary:
	var children: Array = []
	if max_depth < 0 or depth < max_depth:
		for child in node.get_children():
			if child is Node:
				children.append(_hastur_collect_tree(child, root, depth + 1, max_depth))

	var script_path := ""
	var node_script = node.get_script()
	if node_script is Resource:
		script_path = (node_script as Resource).resource_path

	return {
		"name": str(node.name),
		"path": "." if node == root else str(root.get_path_to(node)),
		"absolute_path": str(node.get_path()),
		"type": node.get_class(),
		"script": script_path,
		"child_count": node.get_child_count(),
		"children": children,
	}

func execute(executeContext):
	var root := _hastur_get_root(executeContext)
	if root == null:
		executeContext.output("data", JSON.stringify({"ok": false, "error": "No editable or running scene root found"}))
		return
	var start := _hastur_find_node(root, ${gdStringLiteral(nodePath)})
	if start == null:
		executeContext.output("data", JSON.stringify({"ok": false, "error": "Node not found", "node_path": ${gdStringLiteral(nodePath)}}))
		return
	var max_depth := ${maxDepth}
	executeContext.output("data", JSON.stringify([_hastur_collect_tree(start, root, 0, max_depth)]))
`
}

function buildGetScript({ nodePath, property }: { nodePath: string; property: string }): string {
	return `${commonGodotHelpers()}

func execute(executeContext):
	var root := _hastur_get_root(executeContext)
	var node := _hastur_find_node(root, ${gdStringLiteral(nodePath)}) if root != null else null
	if node == null:
		executeContext.output("data", JSON.stringify({"ok": false, "error": "Node not found", "node_path": ${gdStringLiteral(nodePath)}}))
		return
	var value = node.get(${gdStringLiteral(property)})
	executeContext.output("data", JSON.stringify({
		"ok": true,
		"node_path": ${gdStringLiteral(nodePath)},
		"property": ${gdStringLiteral(property)},
		"value": _hastur_encode_variant(value),
	}))
`
}

function buildSetScript({ nodePath, property, value }: { nodePath: string; property: string; value: unknown }): string {
	return `${commonGodotHelpers()}

func execute(executeContext):
	var root := _hastur_get_root(executeContext)
	var node := _hastur_find_node(root, ${gdStringLiteral(nodePath)}) if root != null else null
	if node == null:
		executeContext.output("data", JSON.stringify({"ok": false, "error": "Node not found", "node_path": ${gdStringLiteral(nodePath)}}))
		return
	node.set(${gdStringLiteral(property)}, ${gdLiteral(value)})
	executeContext.output("data", JSON.stringify({
		"ok": true,
		"node_path": ${gdStringLiteral(nodePath)},
		"property": ${gdStringLiteral(property)},
		"value": _hastur_encode_variant(node.get(${gdStringLiteral(property)})),
	}))
`
}

function buildCallScript({ nodePath, method, args }: { nodePath: string; method: string; args: unknown[] }): string {
	return `${commonGodotHelpers()}

func execute(executeContext):
	var root := _hastur_get_root(executeContext)
	var node := _hastur_find_node(root, ${gdStringLiteral(nodePath)}) if root != null else null
	if node == null:
		executeContext.output("data", JSON.stringify({"ok": false, "error": "Node not found", "node_path": ${gdStringLiteral(nodePath)}}))
		return
	if not node.has_method(${gdStringLiteral(method)}):
		executeContext.output("data", JSON.stringify({"ok": false, "error": "Method not found", "node_path": ${gdStringLiteral(nodePath)}, "method": ${gdStringLiteral(method)}}))
		return
	var result = node.callv(${gdStringLiteral(method)}, ${gdArrayLiteral(args)})
	executeContext.output("data", JSON.stringify({
		"ok": true,
		"node_path": ${gdStringLiteral(nodePath)},
		"method": ${gdStringLiteral(method)},
		"return_value": _hastur_encode_variant(result),
	}))
`
}

function commonGodotHelpers(): string {
	return `extends RefCounted

func _hastur_get_root(executeContext):
	if executeContext.editor_plugin != null:
		var editor_interface = executeContext.editor_plugin.get_editor_interface()
		if editor_interface != null:
			var edited_root = editor_interface.get_edited_scene_root()
			if edited_root != null:
				return edited_root

	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree := main_loop as SceneTree
		if tree.current_scene != null:
			return tree.current_scene
		return tree.root
	return null

func _hastur_find_node(root: Node, path_text: String):
	if root == null:
		return null
	if path_text == "" or path_text == ".":
		return root
	return root.get_node_or_null(NodePath(path_text))

func _hastur_encode_variant(value):
	match typeof(value):
		TYPE_NIL:
			return null
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME:
			return str(value)
		TYPE_NODE_PATH:
			return {"__godot_type": "NodePath", "path": str(value)}
		TYPE_VECTOR2:
			return {"__godot_type": "Vector2", "x": value.x, "y": value.y}
		TYPE_VECTOR2I:
			return {"__godot_type": "Vector2i", "x": value.x, "y": value.y}
		TYPE_VECTOR3:
			return {"__godot_type": "Vector3", "x": value.x, "y": value.y, "z": value.z}
		TYPE_VECTOR3I:
			return {"__godot_type": "Vector3i", "x": value.x, "y": value.y, "z": value.z}
		TYPE_COLOR:
			return {"__godot_type": "Color", "r": value.r, "g": value.g, "b": value.b, "a": value.a}
		TYPE_ARRAY:
			var result: Array = []
			for item in value:
				result.append(_hastur_encode_variant(item))
			return result
		TYPE_DICTIONARY:
			var result := {}
			for key in value.keys():
				result[str(key)] = _hastur_encode_variant(value[key])
			return result
		TYPE_OBJECT:
			if value is Node:
				return {"__godot_type": "Node", "name": str(value.name), "path": str(value.get_path()), "type": value.get_class()}
			if value is Resource:
				return {"__godot_type": "Resource", "path": value.resource_path, "type": value.get_class()}
			return str(value)
		_:
			return str(value)
`
}

function gdArrayLiteral(values: unknown[]): string {
	return `[${values.map((value) => gdLiteral(value)).join(', ')}]`
}

function gdLiteral(value: unknown): string {
	if (value === null) return 'null'
	if (typeof value === 'string') return gdStringLiteral(value)
	if (typeof value === 'boolean') return value ? 'true' : 'false'
	if (typeof value === 'number') {
		if (!Number.isFinite(value)) throw new Error('Only finite numbers can be sent to Godot')
		return String(value)
	}
	if (Array.isArray(value)) return gdArrayLiteral(value)
	if (typeof value === 'object' && value) {
		const object = value as JsonObject
		const type = object.__godot_type
		if (typeof type === 'string') return gdTypedLiteral(type, object)
		return `{${Object.entries(object)
			.map(([key, item]) => `${gdStringLiteral(key)}: ${gdLiteral(item)}`)
			.join(', ')}}`
	}
	throw new Error(`Unsupported value type: ${typeof value}`)
}

function gdTypedLiteral(type: string, object: JsonObject): string {
	switch (type) {
		case 'Vector2':
			return `Vector2(${gdNumber(object.x)}, ${gdNumber(object.y)})`
		case 'Vector2i':
			return `Vector2i(${gdInt(object.x)}, ${gdInt(object.y)})`
		case 'Vector3':
			return `Vector3(${gdNumber(object.x)}, ${gdNumber(object.y)}, ${gdNumber(object.z)})`
		case 'Vector3i':
			return `Vector3i(${gdInt(object.x)}, ${gdInt(object.y)}, ${gdInt(object.z)})`
		case 'Color':
			return `Color(${gdNumber(object.r)}, ${gdNumber(object.g)}, ${gdNumber(object.b)}, ${gdNumber(object.a ?? 1)})`
		case 'NodePath':
			return `NodePath(${gdStringLiteral(String(object.path ?? ''))})`
		case 'StringName':
			return `StringName(${gdStringLiteral(String(object.value ?? ''))})`
		default:
			throw new Error(`Unsupported Godot value type: ${type}`)
	}
}

function gdNumber(value: unknown): string {
	if (typeof value !== 'number' || !Number.isFinite(value)) {
		throw new Error('Godot numeric value must be a finite number')
	}
	return String(value)
}

function gdInt(value: unknown): string {
	if (!Number.isInteger(value)) {
		throw new Error('Godot integer value must be an integer')
	}
	return String(value)
}

function gdStringLiteral(value: string): string {
	return JSON.stringify(value)
}

function bodyObject(body: unknown): JsonObject {
	return body && typeof body === 'object' && !Array.isArray(body) ? body as JsonObject : {}
}

function optionalString(value: unknown): string | undefined {
	return typeof value === 'string' && value !== '' ? value : undefined
}

function requireString(body: JsonObject, field: string): ApiResponse | null {
	if (typeof body[field] !== 'string' || body[field] === '') {
		return { success: false, error: `Missing required field: ${field}` }
	}
	return null
}

function normalizeMaxDepth(value: unknown): number | string {
	if (value === undefined || value === null || value === '') return DEFAULT_TREE_DEPTH
	if (!Number.isInteger(value) || (value as number) < -1) {
		return 'Field max_depth must be an integer greater than or equal to -1'
	}
	return value as number
}

function normalizeTimeoutMs(value: unknown): number | string | undefined {
	if (value === undefined || value === null || value === '') return undefined
	if (!Number.isInteger(value) || (value as number) <= 0 || (value as number) > MAX_TIMEOUT_MS) {
		return `Field timeout_ms must be an integer between 1 and ${MAX_TIMEOUT_MS}`
	}
	return value as number
}
