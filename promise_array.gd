###
### Helper class for the [Promise] classes wait_any and wait_all functions
### Manages an array of promises.
###
class_name PromiseArray
extends Object

# Signal emitted when the first promise in the array of promises has finished.
signal first_promise_finished

var _promises: Array[Promise]

var _is_first_finished: bool = false
var _first_finished_res: Array

func _init(promises: Array[Promise]):
    _promises = promises
    
    for pr: Promise in _promises:
        pr.on_finished.connect(func(res):
            if _is_first_finished:
                return
            
            _is_first_finished = true
            _first_finished_res = [ res, pr.getCoroutine() ]    
            first_promise_finished.emit()
            )

## Return a Promise whose result is an array where [0] is the result of the first finished promise, and [1] is the promises coroutine.
func result_any() -> Promise:
    return Promise.new(_result_any)

## Return a Promise whose result is an array of all the stored promises results
func result_all() -> Promise:
    return Promise.new(_result_all)

func _result_any() -> Array:
    if _is_first_finished:
        return _first_finished_res
    
    await first_promise_finished

    return await _result_any()
    
func _result_all() -> Array:
    var res := []

    for pr: Promise in _promises:
        res.append(await pr.result())

    return res
