
// Types
export interface Todo {
    id: string;
    text: string;
    completed: boolean;
    children: Todo[];
}