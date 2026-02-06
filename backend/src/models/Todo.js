/**
 * Todo Model
 * Firestore schema for todo documents
 */
const { collections, admin } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

/**
 * Todo Schema:
 * {
 *   id: string,
 *   userId: string,
 *   title: string,
 *   description: string | null,
 *   status: 'pending' | 'in_progress' | 'completed',
 *   priority: 'low' | 'medium' | 'high',
 *   dueDate: timestamp | null,
 *   createdAt: timestamp,
 *   updatedAt: timestamp
 * }
 */

class TodoModel {
    static collection = collections.todos;

    /**
     * Create a new todo
     */
    static async create(todoData) {
        const id = uuidv4();
        const now = admin.firestore.FieldValue.serverTimestamp();

        const todo = {
            id,
            userId: todoData.userId,
            title: todoData.title,
            description: todoData.description || null,
            status: todoData.status || 'pending',
            priority: todoData.priority || 'medium',
            dueDate: todoData.dueDate ? new Date(todoData.dueDate) : null,
            createdAt: now,
            updatedAt: now,
        };

        await this.collection.doc(id).set(todo);
        return { ...todo, id, createdAt: new Date(), updatedAt: new Date() };
    }

    /**
     * Find todo by ID
     */
    static async findById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        return this._formatTodo(doc.data());
    }

    /**
     * Find todos by user ID with optional filters
     */
    static async findByUserId(userId, options = {}) {
        const { limit = 50, status, priority, sortBy = 'createdAt', sortOrder = 'desc' } = options;

        let query = this.collection.where('userId', '==', userId);

        if (status) {
            query = query.where('status', '==', status);
        }

        if (priority) {
            query = query.where('priority', '==', priority);
        }

        // query = query.orderBy(sortBy, sortOrder).limit(limit);

        const snapshot = await query.get();
        let todos = snapshot.docs.map(doc => this._formatTodo(doc.data()));

        // In-memory sort and limit to avoid missing index errors
        todos.sort((a, b) => {
            const valA = new Date(a[sortBy] || 0).getTime();
            const valB = new Date(b[sortBy] || 0).getTime();
            return sortOrder === 'desc' ? valB - valA : valA - valB;
        });

        return todos.slice(0, limit);
    }

    /**
     * Update todo
     */
    static async update(id, updates) {
        const updateData = {
            ...updates,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Handle dueDate conversion
        if (updates.dueDate !== undefined) {
            updateData.dueDate = updates.dueDate ? new Date(updates.dueDate) : null;
        }

        await this.collection.doc(id).update(updateData);
        return this.findById(id);
    }

    /**
     * Toggle todo status
     */
    static async toggleStatus(id) {
        const todo = await this.findById(id);
        if (!todo) return null;

        const statusFlow = {
            'pending': 'in_progress',
            'in_progress': 'completed',
            'completed': 'pending',
        };

        const newStatus = statusFlow[todo.status] || 'pending';

        return this.update(id, { status: newStatus });
    }

    /**
     * Delete todo
     */
    static async delete(id) {
        await this.collection.doc(id).delete();
        return true;
    }

    /**
     * Get todo statistics for user
     */
    static async getStatsByUserId(userId) {
        const snapshot = await this.collection
            .where('userId', '==', userId)
            .get();

        const stats = {
            total: 0,
            pending: 0,
            in_progress: 0,
            completed: 0,
            high_priority: 0,
        };

        snapshot.docs.forEach(doc => {
            const todo = doc.data();
            stats.total++;
            stats[todo.status] = (stats[todo.status] || 0) + 1;
            if (todo.priority === 'high') {
                stats.high_priority++;
            }
        });

        return stats;
    }

    /**
     * Format todo timestamps
     */
    static _formatTodo(todo) {
        if (!todo) return null;
        return {
            ...todo,
            createdAt: todo.createdAt?.toDate?.() || todo.createdAt,
            updatedAt: todo.updatedAt?.toDate?.() || todo.updatedAt,
            dueDate: todo.dueDate?.toDate?.() || todo.dueDate,
        };
    }
}

module.exports = TodoModel;
