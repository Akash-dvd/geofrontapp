"""Chain class for executing sequential tasks with try/catch error handling."""

from typing import Any, Dict, List, Optional
import traceback


class Chain:
  """Executes a chain of tasks sequentially with try/catch error handling.
  
  Each task is defined as:
    {
      "class_name": callable,  # Direct callable object (function, method, etc.)
      "array": [...],          # Positional arguments
      "dictionary": {...}      # Keyword arguments
    }
  
  Tasks are executed in order, with results passed between tasks.
  Only direct callable objects are supported (no string-based class names).
  """

  def __init__(self, tasks: List[Dict[str, Any]]):
    """Initialize chain with list of task definitions.
    
    Args:
      tasks: List of task definitions, each with class_name, array, and dictionary
    """
    self.tasks = tasks
    self.results = []
    self.errors = []

  def execute(self, initial_input: Any = None) -> Dict[str, Any]:
    """Execute all tasks sequentially.
    
    Args:
      initial_input: Initial input for the first task
    
    Returns:
      Dictionary with 'results' (list of task results) and 'errors' (list of errors)
    """
    current_output = initial_input
    
    for idx, task in enumerate(self.tasks):
      try:
        class_name = task.get("class_name")
        array_args = task.get("array", [])
        dict_kwargs = task.get("dictionary", {})
        
        if not class_name:
          raise ValueError(f"Task {idx} missing 'class_name'")
        
        # Only callable objects are supported
        if not callable(class_name):
          raise TypeError(f"Task {idx}: 'class_name' must be a callable object, got {type(class_name).__name__}")
        
        # Call the callable directly
        if current_output is not None:
          result = class_name(current_output, *array_args, **dict_kwargs)
        else:
          result = class_name(*array_args, **dict_kwargs)
        
        # Get class_name string for logging
        class_name_str = getattr(class_name, '__name__', str(class_name))
        
        self.results.append({
          "task_index": idx,
          "class_name": class_name_str,
          "result": result,
          "success": True
        })
        
        # Pass result to next task
        current_output = result
        
      except Exception as exc:
        class_name = task.get("class_name", None)
        class_name_str = getattr(class_name, '__name__', str(class_name)) if class_name else "unknown"
        
        error_info = {
          "task_index": idx,
          "class_name": class_name_str,
          "error": str(exc),
          "traceback": traceback.format_exc(),
          "success": False
        }
        self.errors.append(error_info)
        self.results.append(error_info)
        
        # Stop execution on error
        break
    
    return {
      "results": self.results,
      "errors": self.errors,
      "final_output": current_output
    }

