import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// Mock firebase modules before importing anything that uses them
jest.mock('firebase/app', () => ({ initializeApp: jest.fn(() => ({})) }));
jest.mock('firebase/auth', () => ({
  getAuth: jest.fn(() => ({})),
  onAuthStateChanged: jest.fn(),
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
  auth: { currentUser: null, onAuthStateChanged: jest.fn() },
  db: {},
}));

import { AuthProvider, useAuth } from '../context/AuthContext';
import { MemoryRouter } from 'react-router-dom';
import * as firebaseService from '../services/firebase';

// AuthContext uses auth.onAuthStateChanged from the firebase service (not firebase/auth directly)
const mockOnAuthStateChanged = (firebaseService.auth as any).onAuthStateChanged as jest.Mock;

// Test consumer component
const TestConsumer: React.FC = () => {
  const { currentUser, loading } = useAuth();
  return (
    <div>
      <div data-testid="loading">{loading ? 'loading' : 'ready'}</div>
      <div data-testid="user">{currentUser ? currentUser.email : 'no-user'}</div>
    </div>
  );
};

describe('AuthContext', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('provides context values to children', async () => {
    // Simulate no user logged in
    mockOnAuthStateChanged.mockImplementation((callback: (user: null) => void) => {
      callback(null);
      return jest.fn(); // unsubscribe
    });

    render(
      <MemoryRouter>
        <AuthProvider>
          <TestConsumer />
        </AuthProvider>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByTestId('loading')).toHaveTextContent('ready');
    });
    expect(screen.getByTestId('user')).toHaveTextContent('no-user');
  });

  it('sets currentUser when firebase reports authenticated user', async () => {
    const mockUser = {
      uid: 'user123',
      email: 'test@example.com',
      displayName: 'Test User',
      getIdTokenResult: jest.fn().mockResolvedValue({ claims: { admin: false } }),
    };

    mockOnAuthStateChanged.mockImplementation((callback: (user: typeof mockUser) => void) => {
      callback(mockUser);
      return jest.fn();
    });

    render(
      <MemoryRouter>
        <AuthProvider>
          <TestConsumer />
        </AuthProvider>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByTestId('loading')).toHaveTextContent('ready');
    });
    expect(screen.getByTestId('user')).toHaveTextContent('test@example.com');
  });

  it('sets admin role when user has admin claim', async () => {
    const mockUser = {
      uid: 'admin123',
      email: 'admin@example.com',
      displayName: 'Admin User',
      getIdTokenResult: jest.fn().mockResolvedValue({ claims: { admin: true } }),
    };

    mockOnAuthStateChanged.mockImplementation((callback: (user: typeof mockUser) => void) => {
      callback(mockUser);
      return jest.fn();
    });

    const AdminConsumer: React.FC = () => {
      const { currentUser } = useAuth();
      return <div data-testid="role">{currentUser?.role || 'none'}</div>;
    };

    render(
      <MemoryRouter>
        <AuthProvider>
          <AdminConsumer />
        </AuthProvider>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByTestId('role')).toHaveTextContent('admin');
    });
  });

  it('falls back to user role when getIdTokenResult fails', async () => {
    const mockUser = {
      uid: 'user456',
      email: 'fallback@example.com',
      displayName: 'Fallback User',
      getIdTokenResult: jest.fn().mockRejectedValue(new Error('Token error')),
    };

    mockOnAuthStateChanged.mockImplementation((callback: (user: typeof mockUser) => void) => {
      callback(mockUser);
      return jest.fn();
    });

    const RoleConsumer: React.FC = () => {
      const { currentUser } = useAuth();
      return <div data-testid="role">{currentUser?.role || 'none'}</div>;
    };

    render(
      <MemoryRouter>
        <AuthProvider>
          <RoleConsumer />
        </AuthProvider>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByTestId('role')).toHaveTextContent('user');
    });
  });

  it('throws when useAuth is used outside AuthProvider', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    const BadConsumer: React.FC = () => {
      useAuth();
      return null;
    };

    expect(() => render(<BadConsumer />)).toThrow('useAuth must be used within an AuthProvider');
    consoleSpy.mockRestore();
  });
});
