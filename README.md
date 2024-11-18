# PerpetuaFund Smart Contract

## Overview
PerpetuaFund is a sophisticated yield-bearing charity fund implemented as a smart contract on the Stacks blockchain. It enables donors to contribute STX tokens that generate yield, which can then be distributed to registered charities. The contract features a unique inheritance system with customizable tiers and time-locked notifications.

## Key Features

### 1. Donation Management
- Users can donate STX tokens to the fund
- All donations are tracked per donor
- Total pool balance and yield are maintained transparently
- Generates a 5% simulated yield on the total pool balance

### 2. Charity System
- Contract owner can register approved charities
- Each charity has a dedicated address and vote count
- Users can vote for their preferred charities
- Transparent distribution of generated yield to charities

### 3. Inheritance Tier System
- Three customizable inheritance tiers (1-3)
- Each tier supports:
  - Custom inactivity period
  - Designated beneficiary
  - Specified percentage of funds
  - Time-locked notifications
- Automatic beneficiary notification system
- Activity tracking for inheritance triggers

### 4. Time-Locked Notifications
- Automated notification system for beneficiaries
- Tracks last activity time
- Unlocking periods based on tier settings
- Beneficiary status verification

## Functions

### Public Functions

#### Donation Management
- `donate()`: Contribute STX tokens to the fund
- `generate-yield()`: Generate yield from the pool (5% simulation)
- `distribute-yield(charity)`: Distribute accumulated yield to a specific charity

#### Charity Management
- `add-charity(name, address)`: Register a new charity (owner only)
- `vote-for-charity(name)`: Vote for a preferred charity
- `view-balance()`: Check total pool and current yield

#### Inheritance Management
- `set-inheritance-tier(tier, inactivity-period, beneficiary, percentage)`: Configure inheritance tier
- `remove-inheritance-tier(tier)`: Remove an inheritance tier
- `check-and-notify-beneficiaries()`: Check and update beneficiary notifications

### Read-Only Functions
- `get-donation(donor)`: View donation amount for a specific donor
- `get-charity-info(name)`: Get charity details
- `get-total-donations()`: View total pool balance
- `get-total-yield()`: Check current yield
- `get-last-activity-time()`: Get timestamp of last activity
- `get-beneficiary-notification(beneficiary, owner)`: Check beneficiary notification status
- `get-inheritance-tier(owner, tier)`: View inheritance tier details

## Error Codes
- `u100`: Owner-only operation failed
- `u101`: Insufficient funds
- `u102`: Charity not found
- `u103`: Already voted
- `u104`: Transfer failed
- `u105`: Invalid tier
- `u106`: Beneficiary not found
- `u107`: Not a beneficiary
- `u108`: Not unlocked

## Usage

### Setting Up Inheritance
```clarity
;; Set up Tier 1 inheritance (30% after 52 weeks of inactivity)
(contract-call? .perpetuafund set-inheritance-tier u1 u52 'BENEFICIARY-ADDRESS u30)

;; Set up Tier 2 inheritance (50% after 104 weeks of inactivity)
(contract-call? .perpetuafund set-inheritance-tier u2 u104 'BENEFICIARY-ADDRESS u50)
```

### Making Donations
```clarity
;; Donate STX tokens
(contract-call? .perpetuafund donate)
```

### Managing Charities
```clarity
;; Add a new charity
(contract-call? .perpetuafund add-charity "CharityName" 'CHARITY-ADDRESS)

;; Vote for a charity
(contract-call? .perpetuafund vote-for-charity "CharityName")
```

## Security Considerations
- All monetary operations are protected with proper checks
- Inheritance system includes time-locks and verification
- Only contract owner can add charities
- One vote per user for charity voting
- Protected beneficiary notification system

## License
MIT License

Copyright (c) 2024 PerpetuaFund

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contributing
We welcome contributions to the PerpetuaFund smart contract! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please make sure to update tests as appropriate and adhere to the existing coding style.