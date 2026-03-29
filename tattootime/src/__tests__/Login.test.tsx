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

const mockLogin = jest.fn();
const mockNavigate = jest.fn();

jest.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    currentUser: null,
    loading: false,
    login: mockLogin,
    logout: jest.fn(),
    register: jest.fn(),
  }),
}));

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

import Login from '../pages/Login';

const renderLogin = () =>
  render(
    <MemoryRouter>
      <Login />
    </MemoryRouter>
  );

describe('Login Page', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders login form', () => {
    renderLogin();
    expect(screen.getAllByText(/Anmelden/i)[0]).toBeInTheDocument();
  });

  it('has email and password inputs', () => {
    renderLogin();
    expect(screen.getByLabelText(/E-Mail Adresse/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Passwort/i)).toBeInTheDocument();
  });

  it('updates email field when user types', () => {
    renderLogin();
    const emailInput = screen.getByLabelText(/E-Mail Adresse/i);
    fireEvent.change(emailInput, { target: { value: 'test@test.com' } });
    expect(emailInput).toHaveValue('test@test.com');
  });

  it('updates password field when user types', () => {
    renderLogin();
    const passwordInput = screen.getByLabelText(/Passwort/i);
    fireEvent.change(passwordInput, { target: { value: 'pass123' } });
    expect(passwordInput).toHaveValue('pass123');
  });

  it('calls login on form submit', async () => {
    mockLogin.mockResolvedValue(undefined);
    renderLogin();

    fireEvent.change(screen.getByLabelText(/E-Mail Adresse/i), { target: { value: 'user@test.com' } });
    fireEvent.change(screen.getByLabelText(/Passwort/i), { target: { value: 'password123' } });

    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('user@test.com', 'password123');
    });
  });

  it('navigates to dashboard on successful login', async () => {
    mockLogin.mockResolvedValue(undefined);
    renderLogin();

    fireEvent.change(screen.getByLabelText(/E-Mail Adresse/i), { target: { value: 'user@test.com' } });
    fireEvent.change(screen.getByLabelText(/Passwort/i), { target: { value: 'password123' } });
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/dashboard');
    });
  });

  it('shows error message on failed login', async () => {
    mockLogin.mockRejectedValue(new Error('Login failed'));
    renderLogin();

    fireEvent.change(screen.getByLabelText(/E-Mail Adresse/i), { target: { value: 'bad@test.com' } });
    fireEvent.change(screen.getByLabelText(/Passwort/i), { target: { value: 'wrongpass' } });
    fireEvent.submit(document.querySelector('form')!);

    await waitFor(() => {
      expect(screen.getByText(/Anmeldung fehlgeschlagen/i)).toBeInTheDocument();
    });
  });
});
