import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

// Mock Firebase
jest.mock('firebase/app', () => ({ initializeApp: jest.fn(() => ({})) }));
jest.mock('firebase/auth', () => ({
  getAuth: jest.fn(() => ({})),
  onAuthStateChanged: jest.fn(() => jest.fn()),
  signInWithEmailAndPassword: jest.fn(),
  signOut: jest.fn(),
  createUserWithEmailAndPassword: jest.fn(),
}));
jest.mock('firebase/firestore', () => ({
  getFirestore: jest.fn(() => ({})),
  collection: jest.fn(),
  getDocs: jest.fn().mockResolvedValue({ docs: [] }),
}));
jest.mock('../services/firebase', () => ({
  auth: {},
  db: {},
}));

const mockRegister = jest.fn();
const mockNavigate = jest.fn();

jest.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    currentUser: null,
    loading: false,
    login: jest.fn(),
    logout: jest.fn(),
    register: mockRegister,
  }),
}));

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

import Register from '../pages/Register';

describe('Register Page', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders registration form', () => {
    render(
      <MemoryRouter>
        <Register />
      </MemoryRouter>
    );
    expect(screen.getAllByText(/Registrieren/i)[0]).toBeInTheDocument();
  });

  it('has email and password fields', () => {
    render(
      <MemoryRouter>
        <Register />
      </MemoryRouter>
    );
    expect(screen.getByLabelText(/E-Mail/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Passwort/i)).toBeInTheDocument();
  });

  it('calls register on form submit', async () => {
    mockRegister.mockResolvedValue(undefined);
    render(
      <MemoryRouter>
        <Register />
      </MemoryRouter>
    );

    fireEvent.change(screen.getByLabelText(/E-Mail/i), { target: { value: 'new@test.com' } });
    fireEvent.change(screen.getByLabelText(/Passwort/i), { target: { value: 'password123' } });
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(mockRegister).toHaveBeenCalledWith('new@test.com', 'password123');
    });
  });

  it('shows error on registration failure', async () => {
    mockRegister.mockRejectedValue(new Error('Registration failed'));
    render(
      <MemoryRouter>
        <Register />
      </MemoryRouter>
    );

    fireEvent.change(screen.getByLabelText(/E-Mail/i), { target: { value: 'fail@test.com' } });
    fireEvent.change(screen.getByLabelText(/Passwort/i), { target: { value: 'badpass' } });
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(screen.getByText(/Registration failed/i)).toBeInTheDocument();
    });
  });

  it('navigates to dashboard on success', async () => {
    mockRegister.mockResolvedValue(undefined);
    render(
      <MemoryRouter>
        <Register />
      </MemoryRouter>
    );

    fireEvent.change(screen.getByLabelText(/E-Mail/i), { target: { value: 'ok@test.com' } });
    fireEvent.change(screen.getByLabelText(/Passwort/i), { target: { value: 'goodpass123' } });
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/dashboard');
    });
  });
});
