-- by mor2000

--------------------
-- UPK_GasStationTrigger (fills trailers and/or shovels with specific fillType)

local UPK_GasStationTrigger_mt = ClassUPK(UPK_GasStationTrigger,UniversalProcessKit)
InitObjectClass(UPK_GasStationTrigger, "UPK_GasStationTrigger")
UniversalProcessKit.addModule("gasstationtrigger",UPK_GasStationTrigger)

function UPK_GasStationTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_GasStationTrigger_mt)
	registerObjectClassName(self, "UPK_GasStationTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_FUEL
	
    self.createFillType = getBoolFromUserAttribute(nodeId, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(nodeId, "pricePerLiter", 0)
	
	self.preferMapDefaultPrice = getBoolFromUserAttribute(nodeId, "preferMapDefaultPrice", false)
	self.pricePerLiterMultiplier = getVectorFromUserAttribute(nodeId, "pricePerLiterMultiplier", "1 1 1")
	self.pricesPerLiter = {}
	
	self.fillOnlyWholeNumbers = getBoolFromUserAttribute(nodeId, "fillOnlyWholeNumbers", false)
	self.amountToFillOfVehicle = {}
	
	-- add/ remove if filling
	
	self.addIfFilling = {}
	self.useAddIfFilling = false
	local addIfFillingArr = getArrayFromUserAttribute(nodeId, "addIfFilling")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(addIfFillingArr)) do
		self:print('add if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.addIfFilling[fillType] = true
		self.useAddIfFilling = true
	end
	
	self.removeIfFilling = {}
	self.useRemoveIfFilling = false
	local removeIfFillingArr = getArrayFromUserAttribute(nodeId, "removeIfFilling")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(removeIfFillingArr)) do
		self:print('remove if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.removeIfFilling[fillType] = true
		self.useRemoveIfFilling = true
	end
	
	-- statName
	
	self.statName=getStringFromUserAttribute(nodeId, "statName")
	local validStatName=false
	if self.statName~=nil then
		for _,v in pairs(FinanceStats.statNames) do
			if self.statName==v then
				validStatName=true
				break
			end
		end
	end
	if not validStatName then
		self.statName="other"
	end

	self.allowedVehicles={}
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(nodeId, "allowCombine", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(nodeId, "allowFuelTrailer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:print('loaded GasStationTrigger successfully')
	
    return self
end

function UPK_GasStationTrigger:delete()
	UPK_GasStationTrigger:superClass().delete(self)
end

function UPK_GasStationTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_GasStationTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isClient and vehicle~=nil then
		if isInTrigger then
			--self:print('is in trigger')
			if vehicle.addFuelFillTrigger~=nil and not vehicle.UPK_gasStationTriggerAdded then
				self.amountToFillOfVehicle[vehicle]=0
				--self:print('adding trigger')
				vehicle:addFuelFillTrigger(self)
				vehicle.UPK_gasStationTriggerAdded = true
			end
		else
			if vehicle.removeFuelFillTrigger~=nil then
				self.amountToFillOfVehicle[vehicle]=nil
				--self:print('removing trigger')
				vehicle:removeFuelFillTrigger(self)
				vehicle.UPK_gasStationTriggerAdded = false
			end
		end
	end
end

UPK_GasStationTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_GasStationTrigger.getPricePerLiter = UPK_FillTrigger.getPricePerLiter

function UPK_GasStationTrigger:fillFuel(trailer, deltaFillLevel) -- tippers, shovels etc
	--self:print('UPK_GasStationTrigger:fillFuel('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		if UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MOTORIZED) then
			return UPK_FillTrigger.fillMotorized(self, trailer, deltaFillLevel)
		end
		return UPK_FillTrigger.fillTrailer(self, trailer, deltaFillLevel)
	end
	return 0
end

function UPK_GasStationTrigger:getIsActivatable(trailer)
	--self:print('trailer:allowFillType(self.fillFillType, false) '..tostring(trailer:allowFillType(self.fillFillType, false)))
	--self:print('self:getFillLevel(self.fillFillType) '..tostring(self:getFillLevel(self.fillFillType)))
	if UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MOTORIZED) then
		return (self:getFillLevel(self.fillFillType)>0 or self.createFillType)
	end
	return UPK_FillTrigger.getIsActivatable(self, trailer)
end

