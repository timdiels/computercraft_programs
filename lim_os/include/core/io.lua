-- path: abs path
-- if path does not exist, returns nil
function io.from_file(path)
	require_(type(path) == "string")

	if not fs.exists(path) then
		return
	end
	
	local f = fs.open(path, 'r')
	if not f then
		Exception("Failed to open: "..path)
	end
	
	local table_ = textutils.unserialize(f.readAll())
	f.close()
	return table_
end

-- path: abs path
function io.to_file(path, table_)
	require_(type(path) == "string")
	require_(type(table_) == "table")
	
	local f = fs.open(path, 'w')
	if not f then
		Exception("Failed to open: "..path)
	end
	
	local str = textutils.serialize(table_)
	f.write(str)
	f.close()
end