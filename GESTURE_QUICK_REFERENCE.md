# Quick Gesture Reference

## Action List - Dual Column Gesture System

### LEFT COLUMN (28px wide) - Task State Management

#### ✓ Checkmark - Complete Task
Draw a V-shape check mark
```
   \
    ✓
```
**Result:** Task marked as complete, checkmark appears

---

#### — Line-Through - Remove Checkmark
Draw a horizontal line through the left column
```
  ————
```
**Result:** Checkmark removed, task becomes incomplete

---

#### > Right Chevron - Next Day
Draw a right-pointing angle
```
  \
   >
  /
```
**Result:** Task moves to tomorrow

---

#### < Left Chevron - Previous Day
Draw a left-pointing angle
```
    /
   <
    \
```
**Result:** Task moves to yesterday

---

### RIGHT COLUMN (Text Area) - Task Deletion

#### — Line-Through - Delete Task
Draw a line through the text
```
  ————————
```
**Result:** Task deleted permanently (left column shows nothing)

---

## How It Works

1. **Dual Canvas System**: Both columns have active gesture canvases
2. **Left Column**: Manages task state (complete, uncomplete, move)
3. **Right Column**: Deletes entire task
4. **Auto-Clear**: Canvas clears automatically after recognition
5. **Instant Action**: Gestures execute immediately upon recognition

## Tips

- **Left column**: Draw gestures that fill most of the 28px width
- **Right column**: Draw a line through text to delete task
- **Line-through**: Simple horizontal stroke (30% of width minimum)
- Make angles pronounced (60-90° works best for chevrons)
- Draw smoothly for better recognition

## Column-Specific Actions

- **Want to remove checkmark?** Draw a line in LEFT column (28px)
- **Want to delete task?** Draw a line through the TEXT (right column)
- **Want to move task?** Draw chevron (< or >) in LEFT column
- **Want to complete task?** Draw checkmark (✓) in LEFT column

## Input Methods

- ✏️ Apple Pencil
- 👆 Finger
- Both work equally well on both columns!
