# Gesture Recognition System

## Overview

The Action List in DailyView now supports handwritten gesture recognition for task management. Users can draw gestures in the left column (28px wide) to control tasks without using buttons.

## Supported Gestures

### 1. **Checkmark (✓)**
- **Action**: Marks the task as completed
- **Recognition Pattern**:
  - Two distinct strokes forming a V-shape
  - First stroke goes downward
  - Second stroke goes upward and to the right
  - Angle between strokes: 30-150 degrees
- **Visual Feedback**: Checkmark icon appears after completion

### 2. **Left Chevron (<)**
- **Action**: Moves the task to the previous day
- **Recognition Pattern**:
  - Two strokes forming a "<" shape
  - Apex (point) on the left side
  - First stroke moves leftward
  - Second stroke moves rightward from apex
  - Angle between strokes: 30-150 degrees

### 3. **Right Chevron (>)**
- **Action**: Moves the task to the next day
- **Recognition Pattern**:
  - Two strokes forming a ">" shape
  - Apex (point) on the right side
  - First stroke moves rightward
  - Second stroke moves leftward from apex
  - Angle between strokes: 30-150 degrees

### 4. **Line-Through (—)**
- **Action**: Different behavior based on column location
  - **Left column (28px)**: Removes checkmark (uncompletes task)
  - **Right column (text area)**: Deletes the task entirely
- **Recognition Pattern**:
  - Horizontal line stroke (strikethrough motion)
  - Significant horizontal movement (minimum 30% of width)
  - Allows vertical movement as long as horizontal is dominant
  - Works left-to-right or right-to-left
- **Visual Feedback**:
  - Left column: Checkmark disappears, task becomes incomplete
  - Right column: Task is removed from the list immediately (left column shows nothing)

## Implementation

### Files Created

1. **`GestureRecognitionEngine.swift`**
   - Core recognition logic
   - Analyzes stroke patterns and geometry
   - Calculates confidence scores
   - Supports both PencilKit drawings and raw point arrays

2. **`GestureCanvasView.swift`**
   - UIKit wrapper for PencilKit canvas
   - Captures handwriting input
   - Triggers recognition after each stroke
   - Auto-clears canvas after successful recognition

### Integration

**ActionListRow** (in DailyView.swift):
- **Left column (28px × 27px)**:
  - Shows gesture canvas for all tasks with content
  - Shows checkmark icon for completed tasks with canvas overlay
  - Handles: checkmark, cross-out (uncomplete), chevrons (move)
- **Right column (text area)**:
  - Shows gesture canvas overlay on TextField
  - Handles: cross-out (delete task)
- Shows nothing for empty rows
- Dual-canvas system with separate gesture handlers

## User Experience

1. **Writing a task**: User types text in the right column

2. **Completing a task**: User draws a checkmark in the left column
   - Canvas is present on all tasks with content
   - After drawing, the checkmark is recognized
   - Canvas clears and checkmark icon appears
   - Task is marked as completed in the database

3. **Removing checkmark**: User draws a line in the left column
   - Canvas remains active on completed tasks
   - Draw a horizontal line in the LEFT column (28px)
   - Checkmark is removed, task becomes incomplete

4. **Deleting a task**: User draws a line through the text
   - Canvas overlays the text field in right column
   - Draw a horizontal line through the TEXT
   - Task is deleted from the database immediately
   - Left column shows nothing after deletion

5. **Moving tasks**: User draws chevron in the left column
   - "<" chevron: moves to previous day
   - ">" chevron: moves to next day
   - Task immediately updates to new date

## Technical Details

### Recognition Algorithm

**Checkmark Recognition**:
```
1. Find the lowest point (valley of the V)
2. Split stroke into two segments at valley
3. Verify first segment goes down
4. Verify second segment goes up-right
5. Calculate angle between segments (ideal: 90°)
6. Calculate confidence score (0.0 - 1.0)
7. Accept if confidence > 0.5
```

**Chevron Recognition (< and >)**:
```
1. Find the apex point (leftmost for "<", rightmost for ">")
2. Split stroke into two segments at apex
3. Verify first segment moves toward apex
4. Verify second segment moves away from apex
5. Calculate angle between segments (ideal: 60-90°)
6. Verify proper directionality for chevron shape
7. Calculate confidence score (0.5 - 1.0)
```

### PencilKit Integration

- Uses `PKCanvasView` for handwriting capture
- Supports Apple Pencil and finger input
- Background is transparent to blend with UI
- Ink color: black, width: 2pt
- Auto-clears after successful recognition

### Performance

- Recognition happens in real-time after each stroke
- No delay or processing lag
- Immediate visual feedback
- Database updates are asynchronous

## Future Enhancements

Potential additions:
- Star gesture for marking important
- Circle gesture for adding reminder
- Double-tap for quick complete
- Customizable gesture sensitivity
- Visual preview during drawing
- Undo functionality for deletions

## Accessibility

- Gesture input is optional
- Long-press gesture still available for marking important
- Text input remains primary method
- Keyboard navigation fully supported
