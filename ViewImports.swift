// This file imports all views to make them available throughout the app
// Add this file to your Xcode project to resolve import issues

// Dashboard
@_exported import struct SolarScheduler.DashboardView
@_exported import struct SolarScheduler.DashboardStatsView
@_exported import struct SolarScheduler.DashboardRecentActivityView
@_exported import struct SolarScheduler.DashboardRevenueView
@_exported import struct SolarScheduler.DashboardEquipmentAlertsView
@_exported import struct SolarScheduler.DashboardTimeFilterView
@_exported import struct SolarScheduler.DashboardAlertsView

// Jobs
@_exported import struct SolarScheduler.JobsListView
@_exported import struct SolarScheduler.JobDetailView
@_exported import struct SolarScheduler.AddJobView

// Customers
@_exported import struct SolarScheduler.CustomersListView
@_exported import struct SolarScheduler.CustomerDetailView
@_exported import struct SolarScheduler.AddCustomerView

// Installations
@_exported import struct SolarScheduler.InstallationCalendarView
@_exported import struct SolarScheduler.AddInstallationView
@_exported import struct SolarScheduler.InstallationDetailView

// Inventory
@_exported import struct SolarScheduler.InventoryListView
@_exported import struct SolarScheduler.AddEquipmentView
@_exported import struct SolarScheduler.EquipmentDetailView

// Vendors
@_exported import struct SolarScheduler.VendorsListView
@_exported import struct SolarScheduler.AddVendorView

// Settings
@_exported import struct SolarScheduler.SettingsView
@_exported import struct SolarScheduler.ProfileSettingsView

// Authentication
@_exported import struct SolarScheduler.SignInView
@_exported import struct SolarScheduler.SignUpView

// Common Components
@_exported import struct SolarScheduler.ImagePicker
@_exported import struct SolarScheduler.CameraImagePicker
@_exported import struct SolarScheduler.EquipmentImageView
@_exported import struct SolarScheduler.CrossPlatformImagePicker

// Splash Screen
@_exported import struct SolarScheduler.HeroSplashView
@_exported import struct SolarScheduler.AnimatedSplashView