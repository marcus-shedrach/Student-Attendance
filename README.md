### Student Attendance Smart Contract

A comprehensive Clarity smart contract for tracking student attendance on the Stacks blockchain. This contract provides a secure, decentralized solution for educational institutions to manage student enrollment and attendance records.

## Features

### Core Functionality

- **Student Management**: Add, deactivate, and manage student records
- **Attendance Tracking**: Mark attendance with multiple status options (present, absent, late)
- **Class Sessions**: Create and manage class sessions with timing and statistics
- **Data Validation**: Comprehensive input validation and error handling
- **Authorization Control**: Owner-only access for data modifications


### Security Features

- Input validation for all user data
- Authorization checks on all write operations
- Duplicate prevention for attendance records
- Data integrity validation


## Contract Structure

### Data Maps

- `students`: Stores student information (name, email, enrollment date, status)
- `attendance-records`: Tracks daily attendance with timestamps and notes
- `class-sessions`: Manages class session details and statistics


### Error Codes

- `u100`: Not authorized
- `u101`: Student not found
- `u102`: Student already exists
- `u103`: Invalid date
- `u104`: Attendance record already exists
- `u105`: Invalid attendance status
- `u106`: Invalid student ID


## Usage

### Deployment

Deploy the contract to the Stacks blockchain using Clarinet or Stacks CLI:

```shellscript
clarinet deploy --testnet
```

### Adding Students

```plaintext
(contract-call? .student-attendance add-student "John Doe" "john@example.com")
```

### Marking Attendance

```plaintext
(contract-call? .student-attendance mark-attendance u1 u20240101 "present" (some "On time"))
```

### Creating Class Sessions

```plaintext
(contract-call? .student-attendance create-class-session u20240101 "Math 101" u900 u1000)
```

## Public Functions

### Write Functions (Owner Only)

- `add-student(name, email)`: Register a new student
- `deactivate-student(student-id)`: Deactivate a student account
- `mark-attendance(student-id, date, status, notes)`: Record attendance
- `update-attendance(student-id, date, status, notes)`: Modify existing attendance
- `create-class-session(date, session-name, start-time, end-time)`: Create class session


### Read Functions (Public)

- `get-student(student-id)`: Retrieve student information
- `get-attendance(student-id, date)`: Get attendance record
- `get-class-session(date)`: Get class session details
- `get-total-students()`: Get total enrolled students
- `get-student-attendance-rate(student-id, total-classes)`: Calculate attendance percentage


## Data Validation

The contract includes comprehensive validation for:

- Student ID ranges and existence
- Attendance status values ("present", "absent", "late")
- Date formats and validity
- String length limits
- Authorization checks


## Best Practices

1. **Authorization**: Only the contract owner can modify data
2. **Data Integrity**: All inputs are validated before processing
3. **Error Handling**: Descriptive error codes for debugging
4. **Immutable Records**: Attendance records maintain audit trail
5. **Efficient Storage**: Optimized data structures for gas efficiency


## Testing

Use Clarinet for local testing:

```shellscript
clarinet test
```

