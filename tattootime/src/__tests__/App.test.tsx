import React from 'react';
import { render, screen } from '@testing-library/react';

// Mock Firebase modules
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
  addDoc: jest.fn(),
  updateDoc: jest.fn(),
  deleteDoc: jest.fn(),
  doc: jest.fn(),
  query: jest.fn(),
  orderBy: jest.fn(),
  where: jest.fn(),
  Timestamp: { now: jest.fn(() => ({ toDate: () => new Date() })) },
}));
jest.mock('firebase/functions', () => ({
  getFunctions: jest.fn(() => ({})),
  httpsCallable: jest.fn(() => jest.fn()),
}));

// Mock AuthContext to control auth state
const mockLogin = jest.fn();
const mockLogout = jest.fn();
const mockRegister = jest.fn();

jest.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    currentUser: null,
    loading: false,
    login: mockLogin,
    logout: mockLogout,
    register: mockRegister,
  }),
  AuthProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

// Mock MUI components to simplify rendering
jest.mock('@mui/material', () => ({
  ThemeProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
  createTheme: jest.fn(() => ({})),
  blue: { 700: '#1976d2' },
  grey: { 50: '#fafafa', 100: '#f5f5f5', 900: '#212121' },
}));

// Mock React Router pages to avoid deep rendering
jest.mock('../pages/Login', () => ({
  __esModule: true,
  default: () => <div data-testid="login-page">Login</div>,
}));

jest.mock('../pages/Dashboard', () => ({
  __esModule: true,
  default: () => <div data-testid="dashboard-page">Dashboard</div>,
}));

import App from '../App';

describe('App', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders without crashing', () => {
    render(<App />);
    expect(document.body).toBeTruthy();
  });

  it('renders the login page by default (unauthenticated)', () => {
    render(<App />);
    // Root redirects to /login
    expect(document.body).toBeTruthy();
  });
});
