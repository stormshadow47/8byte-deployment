import { render, screen, fireEvent } from '@testing-library/react'
import TodoForm from '@/components/todo-form'

// Mock Next.js router
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    refresh: jest.fn(),
  }),
}))

// Mock axios
jest.mock('axios')

// Mock react-hot-toast
jest.mock('react-hot-toast', () => ({
  success: jest.fn(),
  error: jest.fn(),
}))

describe('TodoForm', () => {
  it('renders the form input', () => {
    render(<TodoForm />)
    const input = screen.getByPlaceholderText(/enter your todo/i)
    expect(input).toBeInTheDocument()
  })

  it('renders the submit button', () => {
    render(<TodoForm />)
    const button = screen.getByRole('button')
    expect(button).toBeInTheDocument()
  })

  it('allows typing in the input field', () => {
    render(<TodoForm />)
    const input = screen.getByPlaceholderText(/enter your todo/i) as HTMLInputElement
    fireEvent.change(input, { target: { value: 'Test Todo' } })
    expect(input.value).toBe('Test Todo')
  })

  it('shows validation error when submitting empty form', () => {
    render(<TodoForm />)
    const button = screen.getByRole('button')
    fireEvent.click(button)
    const errorMessage = screen.getByText(/todo is required/i)
    expect(errorMessage).toBeInTheDocument()
  })
})
