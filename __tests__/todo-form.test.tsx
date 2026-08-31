import { render, screen, fireEvent, waitFor } from '@testing-library/react'
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

  it('submits the form with todo data', async () => {
    const mockOnSubmit = jest.fn()
    render(<TodoForm onSubmit={mockOnSubmit} />)
    
    const input = screen.getByPlaceholderText(/enter your todo/i)
    const button = screen.getByRole('button')
    
    fireEvent.change(input, { target: { value: 'Test Todo' } })
    fireEvent.click(button)
    
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith({ title: 'Test Todo', completed: false })
    })
  })

  it('clears input after submission', async () => {
    const mockOnSubmit = jest.fn()
    render(<TodoForm onSubmit={mockOnSubmit} />)
    
    const input = screen.getByPlaceholderText(/enter your todo/i) as HTMLInputElement
    const button = screen.getByRole('button')
    
    fireEvent.change(input, { target: { value: 'Test Todo' } })
    fireEvent.click(button)
    
    await waitFor(() => {
      expect(input.value).toBe('')
    })
  })
})
