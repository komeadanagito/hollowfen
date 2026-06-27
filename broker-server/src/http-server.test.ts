import assert from 'node:assert/strict'
import { once } from 'node:events'
import type { Server } from 'node:http'
import test from 'node:test'
import { ExecutorManager } from './executor-manager.js'
import { createHttpApp } from './http-server.js'
import type { ExecuteResult, ExecutorInfo } from './types.js'

const AUTH_TOKEN = 'test-token'

class FakeTcpServer {
	calls: Array<{ executorId: string; code: string; language: string; timeoutMs?: number }> = []
	result: ExecuteResult = {
		request_id: 'request-1',
		compile_success: true,
		compile_error: '',
		run_success: true,
		run_error: '',
		outputs: [['data', JSON.stringify({ ok: true })]],
	}

	async sendExecute(executorId: string, code: string, language: string, timeoutMs?: number): Promise<ExecuteResult> {
		this.calls.push({ executorId, code, language, timeoutMs })
		return this.result
	}
}

function makeExecutor(overrides: Partial<ExecutorInfo> = {}): ExecutorInfo {
	return {
		id: 'executor-1',
		project_name: 'Hollowfen',
		project_path: '/Users/quan/MyFile/GameProject/hollowfen/',
		editor_pid: 123,
		plugin_version: '0.1',
		editor_version: '4.6.2',
		supported_languages: ['gdscript'],
		connected_at: new Date(0).toISOString(),
		status: 'connected',
		type: 'editor',
		...overrides,
	}
}

async function withServer(fn: (baseUrl: string, fakeTcpServer: FakeTcpServer) => Promise<void>): Promise<void> {
	const executorManager = new ExecutorManager()
	executorManager.add(makeExecutor())
	const fakeTcpServer = new FakeTcpServer()
	const app = createHttpApp(executorManager, fakeTcpServer as never, AUTH_TOKEN, 5301, 5302)
	const server = app.listen(0, '127.0.0.1') as Server
	await once(server, 'listening')
	const address = server.address()
	assert(address && typeof address === 'object')
	try {
		await fn(`http://127.0.0.1:${address.port}`, fakeTcpServer)
	} finally {
		await new Promise<void>((resolve, reject) => {
			server.close((err) => (err ? reject(err) : resolve()))
		})
	}
}

async function postJson(baseUrl: string, path: string, body: unknown) {
	const response = await fetch(`${baseUrl}${path}`, {
		method: 'POST',
		headers: {
			Authorization: `Bearer ${AUTH_TOKEN}`,
			'Content-Type': 'application/json',
		},
		body: JSON.stringify(body),
	})
	const json = await response.json()
	return { response, json: json as Record<string, unknown> }
}

test('POST /api/godot/tree executes a scene-tree inspection script against the default executor', async () => {
	await withServer(async (baseUrl, fakeTcpServer) => {
		fakeTcpServer.result.outputs = [['data', JSON.stringify([{ name: 'Root', path: '.', type: 'Node2D', children: [] }])]]

		const { response, json } = await postJson(baseUrl, '/api/godot/tree', { max_depth: 2 })

		assert.equal(response.status, 200)
		assert.deepEqual((json.data as Record<string, unknown>).result, [
			{ name: 'Root', path: '.', type: 'Node2D', children: [] },
		])
		assert.equal(fakeTcpServer.calls.length, 1)
		assert.equal(fakeTcpServer.calls[0].executorId, 'executor-1')
		assert.equal(fakeTcpServer.calls[0].language, 'gdscript')
		assert.match(fakeTcpServer.calls[0].code, /func _hastur_collect_tree/)
		assert.match(fakeTcpServer.calls[0].code, /max_depth := 2/)
	})
})

test('POST /api/godot/node/set serializes typed Godot values and forwards timeout', async () => {
	await withServer(async (baseUrl, fakeTcpServer) => {
		const { response, json } = await postJson(baseUrl, '/api/godot/node/set', {
			node_path: 'PartyManager/Knight',
			property: 'position',
			value: { __godot_type: 'Vector2', x: 12, y: 34 },
			timeout_ms: 1234,
		})

		assert.equal(response.status, 200)
		assert.deepEqual((json.data as Record<string, unknown>).result, { ok: true })
		assert.equal(fakeTcpServer.calls[0].timeoutMs, 1234)
		assert.match(fakeTcpServer.calls[0].code, /_hastur_find_node\(root, "PartyManager\/Knight"\)/)
		assert.match(fakeTcpServer.calls[0].code, /node\.set\("position", Vector2\(12, 34\)\)/)
	})
})

test('POST /api/godot/node/call requires a node_path and method', async () => {
	await withServer(async (baseUrl) => {
		const { response, json } = await postJson(baseUrl, '/api/godot/node/call', { node_path: 'PartyManager' })

		assert.equal(response.status, 400)
		assert.equal(json.success, false)
		assert.equal(json.error, 'Missing required field: method')
	})
})
