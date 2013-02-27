-- Assertions

local function AssertionException(message, level)
	level = level or 1
	error({type="AssertionException", message=message}, level+1)
end

function assert(condition, level, message)
	level = level or 1
	message = message or "Assertion failed"
	if not condition then
		AssertionException(message, level+1)
	end
end

function require_(condition, level)
	level = level or 1
	assert(condition, level+1, 'Require failed')
end

function ensure(condition, level)
	level = level or 1
	assert(condition, level+1, 'Ensure failed')
end