import { ExecutorManager } from './executor-manager.js'
import type { ExecutorInfo, ExecutorType } from './types.js'

export interface ExecutorSelection {
	executor?: ExecutorInfo
	status?: number
	error?: string
	hint?: string
}

export function parseExecutorType(value: unknown): ExecutorType | undefined {
	if (value === undefined || value === null || value === '') {
		return undefined
	}
	if (value === 'editor' || value === 'game') {
		return value
	}
	return undefined
}

export function resolveExecutor(executorManager: ExecutorManager, body: Record<string, unknown>): ExecutorSelection {
	const requestedType = body.type
	const executorType = parseExecutorType(requestedType)
	if (requestedType !== undefined && requestedType !== null && requestedType !== '' && executorType === undefined) {
		return {
			status: 400,
			error: 'Invalid executor type',
			hint: 'Executor type must be "editor" or "game".',
		}
	}

	const executorId = typeof body.executor_id === 'string' ? body.executor_id : ''
	const projectName = typeof body.project_name === 'string' ? body.project_name : ''
	const projectPath = typeof body.project_path === 'string' ? body.project_path : ''

	let executor: ExecutorInfo | undefined
	if (executorId) {
		executor = executorManager.findById(executorId)
		if (executor && executorType && executor.type !== executorType) {
			executor = undefined
		}
	} else if (projectName) {
		executor = executorManager.findByProjectName(projectName, executorType)
	} else if (projectPath) {
		executor = executorManager.findByProjectPath(projectPath, executorType)
	} else {
		executor = executorManager.findDefault(executorType)
	}

	if (!executor) {
		return {
			status: 404,
			error: 'No connected Hastur Executor matched the query',
			hint: 'Use GET /api/executors to list available executors. Provide executor_id, project_name, project_path, or a type when more than one executor is connected.',
		}
	}

	return { executor }
}
