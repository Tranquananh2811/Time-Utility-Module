local TimeUtilityModule = {}

local MarkedTimestampNames = {}
local MarkedTimestamps = {}
local MarkTimestampDebounces = {}

local SecondUnit = 1
local MinuteUnit = SecondUnit * 60
local HourUnit = MinuteUnit * 60
local DayUnit = HourUnit * 24
local WeekUnit = DayUnit * 7
local MonthUnit = DayUnit * 30
local YearUnit = DayUnit * 365
local DecadeUnit = YearUnit * 10
local CenturyUnit = DecadeUnit * 10
local MillenniumUnit = CenturyUnit * 10

local OutputMark = '[TimeUtilityModule]: '

local function CheckForYearAndMonthUnitUpdate()
	local Month = os.date('%B')
	local Year = os.date('%Y')

	local function isLeapYear()
		return Year % 4 == 0 and (Year % 100 ~= 0 or Year % 400 == 0)
	end

	local DaysInMonth = {
		['January'] = 31,
		['February'] = isLeapYear() and 29 or 28,
		['March'] = 31,
		['April'] = 30,
		['May'] = 31,
		['June'] = 30,
		['July'] = 31,
		['August'] = 31,
		['September'] = 30,
		['October'] = 31,
		['November'] = 30,
		['December'] = 31,
	}

	local TotalDaysInYear = 0

	for month, days in pairs(DaysInMonth) do
		TotalDaysInYear = TotalDaysInYear + days
	end

	local DaysInMonthResult = DaysInMonth[Month] or 0
	local DaysInYearResult = TotalDaysInYear

	if DaysInMonthResult ~= 0 and DaysInYearResult ~= 0 then
		YearUnit = DayUnit * DaysInYearResult
		MonthUnit = DayUnit * DaysInMonthResult
	else
		warn(OutputMark .. 'Failed to update YearUnit and MonthUnit -> DaysInMonthResult: ' .. tostring(DaysInMonthResult) .. ', DaysInYearResult: ' .. tostring(DaysInYearResult))
	end
	print(OutputMark .. 'Finished checking for YearUnit and MonthUnit update!!')
end

CheckForYearAndMonthUnitUpdate()

function TimeUtilityModule.GetCurrentDateUnit(GetType)

	GetType = string.lower(GetType)

	local DayOfWeek = os.date('%A')
	local Month = os.date('%B')
	local DayOfMonth = os.date('%d')
	local Year = os.date('%Y')

	if GetType == 'dayofweek' then
		return DayOfWeek
	elseif GetType == 'month' then
		return Month
	elseif GetType == 'dayofmonth' then
		return DayOfMonth
	elseif GetType == 'year' then
		return Year
	elseif GetType == 'all' then
		return DayOfWeek .. ' ' .. Month .. ' ' .. DayOfMonth .. ' ' .. Year
	else
		error(OutputMark .. 'Invalid GetType. Please try again!!')
	end
end

function TimeUtilityModule.FormatSecondToTime(Seconds)
	Seconds = tonumber(Seconds)

	if Seconds < 0 then
			error("Cannot format number less than 0!!")
			return
	elseif Seconds == math.huge then
			error("Cannot format math.huge to time!!")
			return
	elseif Seconds == nil then
			error("Argument #1 is not a number!")
			return
	end

	local TimeUnits = {
			{ MillenniumUnit, "millennium", "millennia" },
			{ CenturyUnit, "century", "centuries" },
			{ DecadeUnit, "decade", "decades" },
			{ YearUnit, "year", "years" },
			{ MonthUnit, "month", "months" },
			{ WeekUnit, "week", "weeks" },
			{ DayUnit, "day", "days" },
			{ HourUnit, "hour", "hours" },
			{ MinuteUnit, "minute", "minutes" },
			{ SecondUnit, "second", "seconds" }
	}

	local Result = {}
	local AddNoneZeroUnit = false

	for _, unit in ipairs(TimeUnits) do
			local value = math.floor(Seconds / unit[1])
			Seconds = Seconds % unit[1]
			if value ~= 0 or AddNoneZeroUnit then
					table.insert(Result, string.format("%d %s%s", value, unit[2], value == 1 and "" or "s"))
					AddNoneZeroUnit = false
			end
	end

	if #Result ~= 0 then
			return table.concat(Result, " and ")
	else
			return '0 seconds'
	end
end

function TimeUtilityModule.ConvertTimeUnitToSecond(Time, UnitName)
	UnitName = string.lower(UnitName)
	local ConversionResult = nil
	local ConversionFactors = {
		['second'] = SecondUnit,
		['minute'] = MinuteUnit,
		['hour'] = HourUnit,
		['day'] = DayUnit,
		['week'] = WeekUnit,
		['month'] = MonthUnit,
		['year'] = YearUnit,
		['decade'] = DecadeUnit,
		['century'] = CenturyUnit,
		['millennium'] = MillenniumUnit
	}

	if ConversionFactors[UnitName] then
		ConversionResult = Time * ConversionFactors[UnitName]
	else
		warn(OutputMark .. "Invalid time unit name!!")
	end

	if ConversionResult ~= nil then
		return ConversionResult
	else
		return nil
	end
end

function TimeUtilityModule.MarkTimestamp(TimeMarkName)
	if type(TimeMarkName) ~= 'string' then
		error(OutputMark .. 'Argument #1 expect to be a string not anything else!!')
		return
	end

	if not MarkTimestampDebounces[TimeMarkName] then
		if MarkedTimestamps[TimeMarkName] == nil then
			MarkedTimestamps[TimeMarkName] = os.time()
			table.insert(MarkedTimestampNames, TimeMarkName)
		else
			error(OutputMark..'You cannot create multiple time stamp with the same name!!')
		end
		MarkTimestampDebounces[TimeMarkName] = true
	end
end

function TimeUtilityModule.ViewMarkedTimestamps()
	coroutine.wrap(function()
		for _, name in ipairs(MarkedTimestampNames) do
			print(name .. ': ' .. (MarkedTimestamps[name] or 'No timestamp found in list!!'))
		end
	end)()
end

function TimeUtilityModule.GetElapsedSecondSinceTimestamp(TimeMarkName)
	local CurrentTimestamp = os.time()
	local MarkedTimestamp = MarkedTimestamps[TimeMarkName]

	if MarkedTimestamp then
		return CurrentTimestamp - MarkedTimestamp
	else
		print(OutputMark .. 'Timestamp can not be found when calculating elapsed seconds!')
		return nil
	end
end

function TimeUtilityModule.GetMarkedTimestamp(TimeMarkName)
	if type(TimeMarkName) ~= 'string' then
		error(OutputMark .. 'Argument #1 expect to be a string not anything else!!')
		return
	end

	return MarkedTimestamps[TimeMarkName]
end

function TimeUtilityModule.UpdateMarkedTimestamp(TimeMarkName)
	MarkedTimestamps[TimeMarkName] = os.time()
end

function TimeUtilityModule.UnmarkTimestamp(TimeMarkName)
	local Timestamp = MarkedTimestamps[TimeMarkName]
	local TimestampName = MarkedTimestampNames[TimeMarkName]
	local MarkTimestampDebounce = MarkTimestampDebounces[TimeMarkName]

	if Timestamp then
		Timestamp = nil
		TimestampName = nil
		MarkTimestampDebounce = nil
		print(OutputMark .. 'Successfully un-marked time stamp!!')
	else
		print(OutputMark .. 'Cannot find time stamp in the list to remove!!')
	end
end

return TimeUtilityModule
