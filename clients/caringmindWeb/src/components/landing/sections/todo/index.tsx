"use client"
// put as an app router to use
import React, { useState } from 'react';
import { Button } from '@/components/landing/ui/button';
import { Checkbox } from '@/components/landing/ui/checkbox';
import { v4 as uuidv4 } from 'uuid';

interface Todo {
    id: string;
    text: string;
    completed: boolean;
    parentId: string | null;
}

const initialTodos: Todo[] = [
    {
        id: '1',
        text: 'Finish Pixar-inspired design',
        completed: false,
        parentId: null,
    },
    {
        id: '2',
        text: 'Implement recursive checkbox logic',
        completed: false,
        parentId: '1',
    },
    {
        id: '3',
        text: 'Add new to-do functionality',
        completed: false,
        parentId: '1',
    },
    {
        id: '4',
        text: 'Implement edit functionality',
        completed: false,
        parentId: null,
    },
];

const TodoList: React.FC = () => {
    const [todos, setTodos] = useState<Todo[]>(initialTodos);

    const toggleTodo = (id: string) => {
        setTodos(
            todos.map((todo) =>
                todo.id === id ? { ...todo, completed: !todo.completed } : todo
            )
        );
    };

    const addTodo = (parentId?: string) => {
        const newTodo: Todo = {
            id: uuidv4(),
            text: 'New Todo',
            completed: false,
            parentId: parentId || null,
        };
        setTodos([...todos, newTodo]);
    };

    const editTodo = (id: string, text: string) => {
        setTodos(
            todos.map((todo) =>
                todo.id === id ? { ...todo, text } : todo
            )
        );
    };

    const deleteTodo = (id: string) => {
        setTodos(todos.filter((todo) => todo.id !== id));
    };

    const getChildTodos = (parentId: string | null): Todo[] => {
        return todos.filter((todo) => todo.parentId === parentId);
    };

    return (
        <main className="flex flex-col items-center justify-center h-screen bg-gradient-to-br from-[#00C9FF] to-[#92FE9D] dark:from-[#141E30] dark:to-[#243B55]">
            <div className="max-w-3xl w-full px-6 py-12 bg-white rounded-lg shadow-lg dark:bg-gray-900">
                <div className="flex items-center justify-between mb-8">
                    <h1 className="text-3xl font-bold text-gray-800 dark:text-gray-100">To-Do List</h1>
                    <Button
                        className="bg-[#00C9FF] hover:bg-[#92FE9D] text-white dark:bg-[#243B55] dark:hover:bg-[#141E30]"
                        size="sm"
                        onClick={() => addTodo()}
                    >
                        Add Task
                    </Button>
                </div>
                <div className="space-y-4">
                    {todos.filter((todo) => todo.parentId === null).map((todo) => (
                        <div key={todo.id}>
                            <div className="flex items-center space-x-4">
                                <Checkbox
                                    checked={todo.completed}
                                    onChange={() => toggleTodo(todo.id)}
                                />
                                <div className="flex-1">
                                    <h3 className="font-medium text-gray-800 dark:text-gray-100">{todo.text}</h3>
                                    {getChildTodos(todo.id).length > 0 && (
                                        <p className="text-gray-500 dark:text-gray-400">
                                            {getChildTodos(todo.id).length} subtask(s)
                                        </p>
                                    )}
                                </div>
                                <div className="flex space-x-2">
                                    <Button
                                        className="text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-100"
                                        size="sm"
                                        variant="outline"
                                        onClick={() => editTodo(todo.id, prompt('Enter new task name', todo.text) || todo.text)}
                                    >
                                        Edit
                                    </Button>
                                    <Button
                                        className="text-red-500 hover:text-red-800 dark:text-red-400 dark:hover:text-red-100"
                                        size="sm"
                                        variant="outline"
                                        onClick={() => deleteTodo(todo.id)}
                                    >
                                        Delete
                                    </Button>
                                </div>
                            </div>
                            {getChildTodos(todo.id).length > 0 && (
                                <div className="space-y-4 pl-8">
                                    {getChildTodos(todo.id).map((childTodo) => (
                                        <div key={childTodo.id} className="flex items-center space-x-4">
                                            <Checkbox
                                                checked={childTodo.completed}
                                                onChange={() => toggleTodo(childTodo.id)}
                                            />
                                            <div className="flex-1">
                                                <h3 className="font-medium text-gray-800 dark:text-gray-100">{childTodo.text}</h3>
                                            </div>
                                            <div className="flex space-x-2">
                                                <Button
                                                    className="text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-100"
                                                    size="sm"
                                                    variant="outline"
                                                    onClick={() => editTodo(childTodo.id, prompt('Enter new task name', childTodo.text) || childTodo.text)}
                                                >
                                                    Edit
                                                </Button>
                                                <Button
                                                    className="text-red-500 hover:text-red-800 dark:text-red-400 dark:hover:text-red-100"
                                                    size="sm"
                                                    variant="outline"
                                                    onClick={() => deleteTodo(childTodo.id)}
                                                >
                                                    Delete
                                                </Button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
        </main>
    );
};

export default TodoList;