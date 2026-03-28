import { PricingService } from './pricingService';
import { MaterialService } from './materialService';
import { NotificationService } from './notificationService';

export class InitializationService {
  // Alle Standarddaten für die neuen Features erstellen
  static async initializeAllDefaultData(): Promise<void> {
    try {
      console.log('Initialisiere Standarddaten für erweiterte Features...');

      // Standard-Preisregeln erstellen
      await this.initializePricingRules();
 console.log(' Preisregeln initialisiert');

      // Standard-Materialien erstellen
      await this.initializeMaterials();
 console.log(' Materialien initialisiert');

      // Standard-Nachsorge-Templates erstellen
      await this.initializeAftercareTemplates();
 console.log(' Nachsorge-Templates initialisiert');

 console.log(' Alle Standarddaten erfolgreich initialisiert!');
    } catch (error) {
      console.error('Fehler bei der Initialisierung der Standarddaten:', error);
      throw error;
    }
  }

  // Standard-Preisregeln erstellen
  static async initializePricingRules(): Promise<void> {
    try {
      const existingRules = await PricingService.getActivePricingRules();
      if (existingRules.length === 0) {
        await PricingService.createDefaultPricingRules();
        console.log('Standard-Preisregeln erstellt');
      } else {
        console.log('Preisregeln existieren bereits, überspringe Initialisierung');
      }
    } catch (error) {
      console.error('Fehler beim Initialisieren der Preisregeln:', error);
      throw error;
    }
  }

  // Standard-Materialien erstellen
  static async initializeMaterials(): Promise<void> {
    try {
      const existingMaterials = await MaterialService.getActiveMaterials();
      if (existingMaterials.length === 0) {
        await MaterialService.createDefaultMaterials();
        console.log('Standard-Materialien erstellt');
      } else {
        console.log('Materialien existieren bereits, überspringe Initialisierung');
      }
    } catch (error) {
      console.error('Fehler beim Initialisieren der Materialien:', error);
      throw error;
    }
  }

  // Standard-Nachsorge-Templates erstellen
  static async initializeAftercareTemplates(): Promise<void> {
    try {
      const existingTemplates = await NotificationService.getActiveAftercareTemplates();
      if (existingTemplates.length === 0) {
        await NotificationService.createDefaultAftercareTemplates();
        console.log('Standard-Nachsorge-Templates erstellt');
      } else {
        console.log('Nachsorge-Templates existieren bereits, überspringe Initialisierung');
      }
    } catch (error) {
      console.error('Fehler beim Initialisieren der Nachsorge-Templates:', error);
      throw error;
    }
  }

  // Prüfen, ob alle erforderlichen Collections existieren
  static async checkRequiredCollections(): Promise<{
    pricingRules: boolean;
    materials: boolean;
    payments: boolean;
    notifications: boolean;
    reviews: boolean;
    customerHistory: boolean;
    aftercareTemplates: boolean;
  }> {
    try {
      const results = {
        pricingRules: false,
        materials: false,
        payments: false,
        notifications: false,
        reviews: false,
        customerHistory: false,
        aftercareTemplates: false
      };

      // Prüfe jede Collection durch Versuch, ein Dokument abzurufen
      try {
        await PricingService.getActivePricingRules();
        results.pricingRules = true;
      } catch (error) {
        console.log('Pricing Rules Collection nicht verfügbar');
      }

      try {
        await MaterialService.getActiveMaterials();
        results.materials = true;
      } catch (error) {
        console.log('Materials Collection nicht verfügbar');
      }

      try {
        await NotificationService.getActiveAftercareTemplates();
        results.aftercareTemplates = true;
      } catch (error) {
        console.log('Aftercare Templates Collection nicht verfügbar');
      }

      // Weitere Collections werden bei Bedarf geprüft
      results.payments = true; // Wird bei erster Zahlung erstellt
      results.notifications = true; // Wird bei erster Benachrichtigung erstellt
      results.reviews = true; // Wird bei erster Bewertung erstellt
      results.customerHistory = true; // Wird bei erstem Historie-Eintrag erstellt

      return results;
    } catch (error) {
      console.error('Fehler beim Prüfen der Collections:', error);
      throw error;
    }
  }

  // System-Status abrufen
  static async getSystemStatus(): Promise<{
    isInitialized: boolean;
    collections: {
      pricingRules: boolean;
      materials: boolean;
      payments: boolean;
      notifications: boolean;
      reviews: boolean;
      customerHistory: boolean;
      aftercareTemplates: boolean;
    };
    recommendations: string[];
  }> {
    try {
      const collections = await this.checkRequiredCollections();
      const isInitialized = Object.values(collections).every(status => status === true);
      
      const recommendations: string[] = [];
      
      if (!collections.pricingRules) {
        recommendations.push('Preisregeln initialisieren für dynamische Preisberechnung');
      }
      if (!collections.materials) {
        recommendations.push('Materialien initialisieren für Verbrauchstracking');
      }
      if (!collections.aftercareTemplates) {
        recommendations.push('Nachsorge-Templates initialisieren für automatische Nachsorge');
      }

      return {
        isInitialized,
        collections,
        recommendations
      };
    } catch (error) {
      console.error('Fehler beim Abrufen des System-Status:', error);
      throw error;
    }
  }
} 