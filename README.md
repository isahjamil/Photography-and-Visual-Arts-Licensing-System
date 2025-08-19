# Photography and Visual Arts Licensing System

A comprehensive blockchain-based system for managing photography licensing, usage tracking, and copyright protection built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides photographers and visual artists with a complete solution for:

- **Image Licensing and Usage Rights Verification** - Transparent licensing with customizable terms and pricing
- **Photo Usage Tracking** - Monitor usage across digital and print media with compliance analytics
- **Transparent Pricing and Licensing Management** - Flexible pricing models with automated fee distribution
- **Portfolio and Client Communication** - Professional portfolio management with integrated client inquiry system
- **Copyright Protection and Unauthorized Use Detection** - Comprehensive reporting and tracking of unauthorized usage

## System Architecture

The system consists of five interconnected Clarity smart contracts:

### 1. Photography Core Contract (`photography-core.clar`)
**Foundation contract managing photographer profiles and image metadata**

- Photographer registration and verification
- Image registration with metadata and ownership tracking
- Profile management and updates
- Basic ownership verification

**Key Functions:**
- `register-photographer` - Register new photographer with profile information
- `register-image` - Register image with metadata and ownership
- `update-photographer-profile` - Update photographer information
- `verify-photographer` - Admin function to verify photographer accounts

### 2. Licensing Manager Contract (`licensing-manager.clar`)
**Comprehensive licensing system with flexible pricing and terms**

- License type creation and management
- Custom photographer pricing structures
- License purchasing with platform fee distribution
- Digital license agreements with signature tracking
- License extension and revocation capabilities

**Key Functions:**
- `create-license-type` - Define new license types with terms and pricing
- `set-photographer-pricing` - Set custom pricing for specific photographers
- `purchase-license` - Purchase license with automatic fee calculation
- `create-license-agreement` - Create digital licensing agreements
- `extend-license` - Extend existing license duration

### 3. Usage Tracker Contract (`usage-tracker.clar`)
**Advanced usage monitoring and compliance system**

- Usage recording across multiple media types (web, print, social, advertising)
- Authorization verification against license terms
- Usage limit enforcement
- Unauthorized usage reporting and investigation
- Comprehensive analytics and compliance metrics

**Key Functions:**
- `record-usage` - Record image usage with authorization verification
- `report-unauthorized-usage` - Report copyright infringement
- `set-usage-limits` - Define usage limits for licenses
- `verify-usage` - Verify legitimacy of reported usage
- `calculate-usage-compliance` - Generate compliance analytics

### 4. Portfolio Manager Contract (`portfolio-manager.clar`)
**Professional portfolio and client communication system**

- Portfolio creation and management
- Collection organization with image galleries
- Client inquiry and communication system
- Access control and sharing permissions
- Portfolio analytics and performance tracking

**Key Functions:**
- `create-portfolio` - Create photographer portfolio
- `create-collection` - Organize images into collections
- `submit-inquiry` - Client inquiry submission system
- `grant-portfolio-access` - Manage portfolio viewing permissions
- `view-portfolio` - Track portfolio views and analytics

### 5. Copyright Protection Contract (`copyright-protection.clar`)
**Advanced copyright protection and enforcement system**

*Note: This contract is referenced in the system architecture but would be implemented as an extension for advanced copyright protection features including automated detection, legal integration, and enforcement mechanisms.*

## Technical Specifications

### Blockchain Platform
- **Blockchain:** Stacks (STX)
- **Smart Contract Language:** Clarity 2.4
- **Development Framework:** Clarinet
- **Testing Framework:** Vitest

### Data Structures

#### Photographer Profile
```clarity
{
  wallet-address: principal,
  name: (string-ascii 100),
  bio: (string-ascii 500),
  portfolio-url: (string-ascii 200),
  contact-email: (string-ascii 100),
  verification-status: bool,
  registration-block: uint,
  total-images: uint
}
