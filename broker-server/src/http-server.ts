import express, { type Request, type Response, type NextFunction } from 'express'
import { ExecutorManager } from './executor-manager.js'
import { TcpServer } from './tcp-server.js'
import { createAuthMiddleware } from './auth.js'
import { resolveExecutor } from './executor-selection.js'
import { createGodotRouter } from './godot-api.js'
import type { ApiResponse } from './types.js'

export function createHttpApp(
	executorManager: ExecutorManager,
	tcpServer: TcpServer,
	authToken: string,
	tcpPort: number,
	httpPort: number,
) {
	const app = express()
	const authMiddleware = createAuthMiddleware(authToken)

	app.use(express.json({ limit: '1mb' }))

	app.get('/api/health', (_req: Request, res: Response) => {
		res.json({
			success: true,
			data: {
				status: 'ok',
				tcp_port: tcpPort,
				http_port: httpPort,
				executors_connected: executorManager.getAll().length,
			},
		})
	})

	app.use('/api', (req: Request, res: Response, next: NextFunction) => {
		if (req.path === '/health') {
			next()
			return
		}
		authMiddleware(req, res, next)
	})

	app.get('/api/executors', (_req: Request, res: Response) => {
		const executors = executorManager.getAll()
		const response: ApiResponse = {
			success: true,
			data: executors,
		}
		if (executors.length === 0) {
			response.hint = 'No Hastur Executors are currently connected. Ensure the Hastur Executor plugin is enabled in a Godot editor and can reach the broker-server.'
		}
		res.json(response)
	})

	app.post('/api/executors', (_req: Request, res: Response) => {
		res.status(405).json({
			success: false,
			error: 'Method not allowed',
			hint: 'GET /api/executors to list executors, POST /api/execute to execute code',
		})
	})

	app.use('/api/godot', createGodotRouter(executorManager, tcpServer))

	app.post('/api/execute', async (req: Request, res: Response) => {
		const { code, timeout_ms } = req.body

		if (!code) {
			res.status(400).json({
				success: false,
				error: 'Missing required field: code',
				hint: 'The request body must include a \'code\' field (string) containing the GDScript code to execute. Example: {"code": "print(\\"hello\\")"}',
			})
			return
		}

		if (typeof timeout_ms !== 'undefined' && (!Number.isInteger(timeout_ms) || timeout_ms <= 0 || timeout_ms > 300000)) {
			res.status(400).json({
				success: false,
				error: 'Field timeout_ms must be an integer between 1 and 300000',
			})
			return
		}

		const selection = resolveExecutor(executorManager, req.body)

		if (!selection.executor) {
			res.status(selection.status || 404).json({
				success: false,
				error: selection.error,
				hint: selection.hint,
			})
			return
		}

		try {
			const result = await tcpServer.sendExecute(selection.executor.id, code, 'gdscript', timeout_ms)
			res.json({ success: true, data: result })
		} catch (err: unknown) {
			const error = err as Error
			if (error.message === 'TIMEOUT') {
				res.status(504).json({
					success: false,
					error: 'Executor execution timed out (30s)',
					hint: 'The code execution took too long. Try simplifying the code or check if the Godot editor is responsive.',
				})
			} else {
				res.status(500).json({
					success: false,
					error: error.message || 'Execution failed',
					hint: 'An unexpected error occurred during code execution.',
				})
			}
		}
	})

	app.use((_req: Request, res: Response) => {
		res.status(404).json({
			success: false,
			error: 'Route not found',
			hint: 'Available endpoints: GET /api/executors - List connected Hastur Executors, POST /api/execute - Execute code on a Hastur Executor',
		})
	})

	return app
}

