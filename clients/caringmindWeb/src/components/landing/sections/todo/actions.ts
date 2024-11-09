// actions.ts
import { Todo } from './types';
import { v4 as uuidv4 } from 'uuid';

export const toggleTodo = async (todos: Todo[], id: string): Promise<Todo[]> => {
    return todos.map((todo) => {
        if (todo.id === id) {
            return { ...todo, completed: !todo.completed };
        }
        return {
            ...todo,
            children: todo.children.map((child) =>
                child.id === id ? { ...child, completed: !child.completed } : child
            ),
        };
    });
};

export const createTodo = async (todos: Todo[], parentId?: string): Promise<Todo[]> => {
    const newTodo: Todo = {
        id: uuidv4(),
        text: 'New Todo',
        completed: false,
        children: [],
    };

    return parentId
        ? todos.map((todo) =>
            todo.id === parentId
                ? { ...todo, children: [...todo.children, newTodo] }
                : todo
        )
        : [...todos, newTodo];
};

export const editTodo = async (todos: Todo[], id: string, text: string): Promise<Todo[]> => {
    return todos.map((todo) => {
        if (todo.id === id) {
            return { ...todo, text };
        }
        return {
            ...todo,
            children: todo.children.map((child) =>
                child.id === id ? { ...child, text } : child
            ),
        };
    });
};