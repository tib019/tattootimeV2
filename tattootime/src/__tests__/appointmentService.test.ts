// Mock firebase before any imports
jest.mock('firebase/app', () => ({ initializeApp: jest.fn(() => ({})) }));

jest.mock('firebase/firestore', () => {
  function FakeTimestamp() {}
  FakeTimestamp.now = jest.fn(() => new (FakeTimestamp as any)());
  (FakeTimestamp.prototype as any).toDate = () => new Date('2025-01-01');
  return {
    getFirestore: jest.fn(() => ({})),
    collection: jest.fn(() => 'appointments-collection'),
    getDocs: jest.fn(),
    addDoc: jest.fn(),
    updateDoc: jest.fn(),
    deleteDoc: jest.fn(),
    doc: jest.fn(() => 'mock-doc-ref'),
    query: jest.fn(),
    orderBy: jest.fn(),
    where: jest.fn(),
    Timestamp: FakeTimestamp,
  };
});

jest.mock('firebase/auth', () => ({
  getAuth: jest.fn(() => ({})),
  onAuthStateChanged: jest.fn(() => jest.fn()),
  signInWithEmailAndPassword: jest.fn(),
}));

jest.mock('../services/firebase', () => ({
  auth: {},
  db: {},
}));

import { getAppointments, addAppointment, updateAppointment, deleteAppointment } from '../services/appointmentService';
import * as firestoreModule from 'firebase/firestore';

const mockGetDocs = firestoreModule.getDocs as jest.Mock;
const mockAddDoc = firestoreModule.addDoc as jest.Mock;
const mockUpdateDoc = firestoreModule.updateDoc as jest.Mock;
const mockDeleteDoc = firestoreModule.deleteDoc as jest.Mock;
const mockQuery = firestoreModule.query as jest.Mock;

describe('appointmentService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getAppointments', () => {
    it('returns empty array when no appointments exist', async () => {
      mockQuery.mockReturnValue('mock-query');
      mockGetDocs.mockResolvedValue({ docs: [] });

      const result = await getAppointments();
      expect(result).toEqual([]);
    });

    it('returns mapped appointments from firestore', async () => {
      mockQuery.mockReturnValue('mock-query');
      mockGetDocs.mockResolvedValue({
        docs: [
          {
            id: 'apt-1',
            data: () => ({
              date: '2025-06-15',
              time: '10:00',
              clientName: 'Anna Schmidt',
              service: 'Tattoo',
              userId: 'user-1',
              createdAt: '2025-01-01T00:00:00.000Z',
            }),
          },
        ],
      });

      const result = await getAppointments();
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('apt-1');
      expect(result[0].clientName).toBe('Anna Schmidt');
    });

    it('throws error when firestore query fails', async () => {
      mockQuery.mockReturnValue('mock-query');
      mockGetDocs.mockRejectedValue(new Error('Firestore error'));

      await expect(getAppointments()).rejects.toThrow('Failed to fetch appointments');
    });
  });

  describe('addAppointment', () => {
    it('adds appointment to firestore', async () => {
      mockAddDoc.mockResolvedValue({ id: 'new-apt' });

      const newAppointment = {
        date: '2025-07-01',
        time: '14:00',
        clientName: 'Max Muster',
        service: 'Beratung',
        userId: 'user-2',
      };

      await addAppointment(newAppointment);
      expect(mockAddDoc).toHaveBeenCalled();
    });

    it('validates date format and throws on invalid date', async () => {
      const invalidAppointment = {
        date: 'not-a-date',
        time: '14:00',
        clientName: 'Max Muster',
        service: 'Beratung',
        userId: 'user-2',
      };

      await expect(addAppointment(invalidAppointment)).rejects.toThrow('Failed to add appointment');
    });

    it('throws when addDoc fails', async () => {
      mockAddDoc.mockRejectedValue(new Error('Write error'));

      await expect(addAppointment({
        date: '2025-07-01',
        time: '14:00',
        clientName: 'Test',
        service: 'Test',
        userId: 'user-1',
      })).rejects.toThrow('Failed to add appointment');
    });
  });

  describe('updateAppointment', () => {
    it('updates appointment in firestore', async () => {
      mockUpdateDoc.mockResolvedValue(undefined);

      await updateAppointment('apt-1', { clientName: 'Updated Name' });
      expect(mockUpdateDoc).toHaveBeenCalled();
    });

    it('throws when updateDoc fails', async () => {
      mockUpdateDoc.mockRejectedValue(new Error('Update error'));

      await expect(updateAppointment('apt-1', { clientName: 'Fail' }))
        .rejects.toThrow();
    });
  });

  describe('deleteAppointment', () => {
    it('deletes appointment from firestore', async () => {
      mockDeleteDoc.mockResolvedValue(undefined);

      await deleteAppointment('apt-1');
      expect(mockDeleteDoc).toHaveBeenCalled();
    });

    it('throws when deleteDoc fails', async () => {
      mockDeleteDoc.mockRejectedValue(new Error('Delete error'));

      await expect(deleteAppointment('apt-1')).rejects.toThrow();
    });
  });
});
