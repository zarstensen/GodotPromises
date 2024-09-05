###
### Wrapper around an awaitable object.
### Allows delaying the await call later in code, by awaiting the result function,
### or using wait_any / wait_all.
###
class_name Promise
extends Object

## Emitted when the [Promise]'s coroutine has finished processing, and has returned a result.
signal on_finished(res)

## Create an empty promise which finishes instantly, and returns null.
static func empty() -> Promise:
    return Promise.new(func():)

## Create a [Promise] from another [Promise], a [Signal], or an async function.
func _init(coroutine: Variant):
    
    if not coroutine is Promise and not coroutine is Signal and not coroutine is Callable:
        var err_msg: String = "%s is not of type 'Promise', 'Signal' or 'Callable'" % coroutine
        
        if OS.is_debug_build():
            assert(false, err_msg)
        else:
            printerr(err_msg)
            return
    
    _coroutine = coroutine

    # Start processing of coroutine without blocking the caller, or requirering an await.
    var coroutine_wrapper = func():
        
        if coroutine is Promise:
            _result = await coroutine.result()
        elif coroutine is Signal:
            _result = await coroutine
        elif coroutine is Callable:
            _result = await coroutine.call()
        
        _finished = true

        on_finished.emit(_result)

    coroutine_wrapper.call()

## Retreive the result of the coroutine.
## this function can be awaited to wait until the coroutine has finished.
func result() -> Variant:
    if _finished:
        return _result
    
    return await on_finished 

func getCoroutine() -> Variant:
    return _coroutine


## Construct a [Promise], which waits for all coroutines to finish,
## and returns an array of results in order of their placement in the [param coroutines] array
static func wait_all(coroutines: Array) -> Promise:
    var promises: Array[Promise] = []
    promises.assign(coroutines.map(func(cr): return Promise.new(cr)))

    return PromiseArray.new(promises).result_all()

## Construct a [Promise], which waits for the first coroutine to finish in an array of coroutines.
## [Promise.result] returns an array where [0] = coroutine result and [1] = the finished promise.
static func wait_any(coroutines: Array) -> Promise:
    var promises: Array[Promise] = []
    promises.assign(coroutines.map(func(cr): return Promise.new(cr)))
    
    return PromiseArray.new(promises).result_any()

var _finished: bool = false

var _result: Variant

var _coroutine: Variant
