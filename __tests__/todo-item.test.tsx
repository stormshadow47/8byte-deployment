import { render, screen } from '@testing-library/react'
import TodoItem from '@/components/todo-item'

describe('TodoItem', () => {
  it('renders the todo title', () => {
    render(<TodoItem id="1" title="Test Todo" completed={false} />)
    expect(screen.getByText('Test Todo')).toBeInTheDocument()
  })

  it('renders delete button', () => {
    render(<TodoItem id="1" title="Test Todo" completed={false} />)
    const deleteButton = screen.getByRole('button')
    expect(deleteButton).toBeInTheDocument()
  })
})
