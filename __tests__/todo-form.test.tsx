import { render, screen } from '@testing-library/react'
import TodoForm from '@/components/todo-form'

describe('TodoForm', () => {
  it('renders the form input', () => {
    render(<TodoForm />)
    const input = screen.getByPlaceholderText(/enter your todo/i)
    expect(input).toBeInTheDocument()
  })

  it('renders the submit button', (): void => {
    render(<TodoForm />)
    const button = screen.getByRole('button')
    expect(button).toBeInTheDocument()
  })
})
