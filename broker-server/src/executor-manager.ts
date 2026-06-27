import type { ExecutorInfo, ExecutorType } from './types.js'

export class ExecutorManager {
	private executors: Map<string, ExecutorInfo> = new Map()

	add(executor: ExecutorInfo): void {
		this.executors.set(executor.id, executor)
	}

	remove(id: string): boolean {
		return this.executors.delete(id)
	}

	get(id: string): ExecutorInfo | undefined {
		return this.executors.get(id)
	}

	getAll(): ExecutorInfo[] {
		return Array.from(this.executors.values())
	}

	findById(id: string): ExecutorInfo | undefined {
		return this.executors.get(id)
	}

	findByProjectName(name: string, type?: ExecutorType): ExecutorInfo | undefined {
		const lower = name.toLowerCase()
		for (const executor of this.executors.values()) {
			if (executor.project_name.toLowerCase().includes(lower) && executor.status === 'connected') {
				if (type && executor.type !== type) continue
				return executor
			}
		}
		return undefined
	}

	findByProjectPath(path: string, type?: ExecutorType): ExecutorInfo | undefined {
		const lower = path.toLowerCase()
		for (const executor of this.executors.values()) {
			if (executor.project_path.toLowerCase().includes(lower) && executor.status === 'connected') {
				if (type && executor.type !== type) continue
				return executor
			}
		}
		return undefined
	}

	findDefault(type?: ExecutorType): ExecutorInfo | undefined {
		const matches = Array.from(this.executors.values()).filter((executor) => {
			if (executor.status !== 'connected') return false
			return type ? executor.type === type : true
		})
		return matches.length === 1 ? matches[0] : undefined
	}
}
