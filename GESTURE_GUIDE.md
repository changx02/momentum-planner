# Gesture Drawing Guide for Action List

## Dual-Column Gesture System

The Action List has **two separate gesture areas**:
- **Left Column (28px)**: Manages task state (complete, uncomplete, move)
- **Right Column (text area)**: Deletes tasks

## Left Column Gestures (28px wide)

### ✓ Checkmark - Mark Task Complete
```
Draw a "check" mark:

    \
     \
      ✓
```
**How to draw:**
1. Start at top-left
2. Draw down and slightly right (first stroke)
3. Continue upward and to the right (second stroke)
4. Forms a V-shape or check symbol

**Result:** Task is marked as completed, checkmark icon appears


### > Right Chevron - Move to Next Day
```
Draw a ">" symbol:

  \
   >
  /
```
**How to draw:**
1. Start at left-middle
2. Draw rightward and downward (first stroke)
3. Continue rightward and upward from the point (second stroke)
3. Forms a ">" pointing right

**Result:** Task moves to the next day


### < Left Chevron - Move to Previous Day
```
Draw a "<" symbol:

    /
   <
    \
```
**How to draw:**
1. Start at right-middle
2. Draw leftward and downward (first stroke)
3. Continue leftward and upward from the point (second stroke)
4. Forms a "<" pointing left

**Result:** Task moves to the previous day


### — Line-Through - Remove Checkmark (Left Column Only)
```
Draw a horizontal line in the left column:

  ————
```
**How to draw:**
1. Draw a horizontal line in the LEFT COLUMN (28px area)
2. Swipe left-to-right or right-to-left
3. Can be slightly diagonal (horizontal movement should be dominant)
4. Minimum 30% of column width

**Result:** Checkmark is removed, task becomes incomplete

---

## Right Column Gesture (Text Area)

### — Line-Through - Delete Entire Task
```
Draw a line through the text:

  ————————————
```
**How to draw:**
1. Draw a line over the TEXT AREA (right column)
2. Swipe left-to-right or right-to-left through the text
3. Natural strikethrough motion
4. Minimum 30% of text width

**Result:** Task is deleted permanently (left column shows nothing)


## Tips for Best Recognition

1. **Draw smoothly** - One continuous motion per gesture
2. **Keep gestures clear** - Make distinct V-shapes
3. **Size matters** - Draw gestures that fill most of the 28px width
4. **Angle is key** - Keep angles between 30-150 degrees for best results
5. **Canvas clears automatically** - After successful recognition, the canvas clears

## Recognition Confidence

The system calculates confidence scores (0.5 - 1.0) based on:
- Angle between strokes (ideal: 60-90°)
- Direction of movement
- Size of the gesture
- Shape clarity

Higher confidence = more accurate recognition = faster response


## What Happens After Drawing

### Left Column Gestures:
1. **Checkmark (✓)**: Task is marked complete → checkmark icon appears
2. **Line-through (—)**: Checkmark is removed → task becomes incomplete
3. **Right chevron (>)**: Task moves to next day → disappears from current day
4. **Left chevron (<)**: Task moves to previous day → disappears from current day

### Right Column Gesture:
1. **Line-through (—)**: Task is deleted → removed from database immediately (left column shows nothing)

The canvas automatically clears after each recognized gesture, ready for the next input.

**Important Notes**:
- **Left column** gesture canvas is always active (even over checkmarks) for uncompleting tasks
- **Right column** gesture canvas overlays the text field for quick deletion
- **After deletion** in right column, left column becomes empty (no checkmark or canvas shows)
- Each column has its own specific functions


## Troubleshooting

**Gesture not recognized?**
- Draw larger (fill the 28px column)
- Make angles more pronounced (closer to 60-90°)
- Draw smoother (avoid jagged lines)
- Ensure clear directionality

**Wrong gesture detected?**
- Slow down your drawing
- Make chevrons more angular (sharper points)
- Keep checkmarks more vertical on the right stroke


## Notes

- Only works on tasks with content (not empty rows)
- **Left column**: Canvas always active for task state management
- **Right column**: Canvas always active for task deletion
- Completed tasks show checkmark icon with invisible canvas overlay in left column
- **Draw line in LEFT column** to remove checkmark
- **Draw line through TEXT** to delete task permanently (left column becomes empty)
- Simple horizontal strikethrough motion
- Works with Apple Pencil or finger input on both columns
