%% Campus Data Script


% NOTE - Use this script if you are looking to investigate the energy and occupancy
% data of a particular building or set of buildings. If this is a new
% datafile, then it would be beneficial to pass this through the individual
% scripts for updating the data metric checklists and observe the quantity
% and quality of data before fully investigating. 
% - 

% ABOUT - By entering the building(s) and data file for a particular month,
% this script will output :
% - An average weekday and weekend profile for each meter 
% - Outside temperature for that month (if BMS supplied)
% - Building temperature measurements (if BMS supplied)
% - A pie chart illustrating the energy consumption split
% - A description of the type of building it is based on the provided data
% - (optional) exporting selected data to an excel file with a sheet per
% building
% - Energy consumption per person
% - Data Quality Metric for Each Meter

clear variables

%% Specify Building(s) to Investigate and Data Files 

Metertype = "Electricity";%input('Which meter(s)?');

% specify building(s) - MAKE SURE IT'S THE SAME ORDER FOR EACH DATASET IF
% MULTIPLE BUILDINGS 
building_name_synetica = input('Which Building(s)? (Enter "serving_revised" as in Synetica Metadata, or press enter if youre not including this data )');
building_name_wifi = input('Which Building(s)? (Enter "serving_revised" as in Wi-Fi Metadata, or press enter if youre not including this data)');
building_names_BMS = input('Which Building(s)? (Enter "serving_revised" as in BMS Metadata, or press enter if youre not including this data)');

got_synetica = ~isempty(building_name_synetica);
got_wifi = ~isempty(building_name_wifi);
got_bms = ~isempty(building_names_BMS);

% specify data file, ENSURE IT IS SAME MONTH
raw_datafile_wifi = [];% INSERT FILE E.G'C:\Users\charl\AppData\Local\Temp\wifi_2020-04.csv';
raw_datafile_bms = [];% INSERT FILE E.G 'C:\Users\charl\AppData\Local\Temp\bms-feb-2020.csv';
raw_datafile_synet = []; % INSERT FILE E.G 'C:\Users\charl\AppData\Local\Temp\synetica-apr-2020.csv';

% specify exportation to excel
excel = input('Export to excel? ("yes" or "no")');
if excel == "yes"
    compile = input('Compiling data?');
    filenAme = input('Filename? (E.g library Example Data.xlsx'); % change as desired, be sure to include .xlsx
end
%% WIFI - Raw Data Extraction

if got_wifi == 1

% ensure variables are of appropriate data type
opts = detectImportOptions(raw_datafile_wifi);
opts = setvartype(opts,{'Building','Floor'},'categorical');

% import the raw wifi data for the chosen month 
wifidata = readtable(raw_datafile_wifi);

% create two new variables to indicate what day of the week and what time of the day each timestamp is 
DayNumber = weekday(wifidata.time); 
timeofDay = timeofday(wifidata.time);
wifidata.Daynumber = DayNumber;
wifidata.Timeofday = timeofDay;

end

%% BMS - Raw Data Extraction

if got_bms == 1

bms_rawdata = readtable(raw_datafile_bms); % import raw data table

bms_rawdata.device_id = categorical(bms_rawdata.device_id);

bms_rawdata = removevars(bms_rawdata, {'param_name','param_type'}); %remove unwanted variables
bms_rawdata.Properties.VariableNames{4} = 'key'; % change variable to match other datasets
bmsmetadata = []; % INSERT BMS METADATA IN THIS FOLDER readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Code\bmsmetadata.xlsx'); 
bmsmetadata.device_id = categorical(bmsmetadata.device_id);

%% BMS - Filter and Join Datasets

% join raw data and new metadata table to get table with wanted variables 
BMS_data = innerjoin(bmsmetadata,bms_rawdata,'Keys',{'device_id','key'});

% filter for data where only measured in degrees 
BMS_data = BMS_data(ismember(BMS_data.units,{'DEGC','DegC','Deg'}),:);

% make memory space 
clear bms_rawdata;

%% Outside Temperature Extraction

weatherdata = BMS_data(BMS_data.device_id == {'{B8C7EAD4-70EF-4C0D-8309-AE001535EA37}'},[5 7 8]);
weatherdata = weatherdata(string(weatherdata.key) == string({'S14'}),2:3);
weatherdata.Properties.VariableNames{1} = 'Outside Weather (DegC)';
weatherdata = table2timetable(weatherdata);
weatherdata = sortrows(weatherdata,'timestamp','ascend');
weatherdata = unique(weatherdata);
weatherdata = rmmissing(weatherdata);
weatherdata = retime(weatherdata, 'regular', 'linear', 'TimeStep', minutes(10));

end


%% SYNETICA - Extract relevent Synetica Data 

if got_synetica == 1

% ensures the specified variables are of type 'categorical'
opts = detectImportOptions(raw_datafile_synet);
opts = setvartype(opts,{'name','units', 'device_id'},'categorical');
               
% import raw synetica data for chosen month 
SyneticaData = readtable(raw_datafile_synet); %imports synetica file chosen by user

opts = detectImportOptions('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica_meter_list_heat.xlsx');
opts = setvartype(opts,{'name','MeterType', 'serving_revised','class','units_after_conversion'},'categorical');

% import the synetica meter list
Syneticameterlist = []; % INSERT SYNET METADATA readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica_meter_list_210122.xlsx');


%% SYNETICA - Join Datasets 

% ensures meters with no 'class' defined' have a definition of 'not defined'
Syneticameterlist.class = fillmissing(Syneticameterlist.class, 'constant', 'not defined');

% filter the meter list for only values from heat meters
Syneticameterlist = Syneticameterlist(Syneticameterlist.MeterType == Metertype,:);

if Metertype == "Electricity"
Syneticameterlist = Syneticameterlist(ismember(Syneticameterlist.units_after_conversion,{'kWh','MWh','KW','MW'}),:);
end

% use innerjoin the combine the appropriatley filtered meter list with the syentica data for the chosen month 
joinedData = innerjoin(Syneticameterlist,SyneticaData,'Keys',{'name'});

% % add the 'day number' and 'time of day' (HH:MM:SS) to the new data table
DayNumber = weekday(joinedData.timestamp); 
timeofDay = timeofday(joinedData.timestamp);
 
joinedData.Daynumber = DayNumber;
joinedData.Timeofday = timeofDay;

end

%% Wifi Data Extraction


if got_wifi == 1

    numberofbuildings =  length(building_name_wifi);

elseif got_synetica == 1 
    
    numberofbuildings =  length(building_name_synetica);
    
elseif got_bms == 1
    
    numberofbuildings =  length(building_name_bms);
    
end

for h = 1:numberofbuildings    
    
  if got_wifi == 1
   
% creates a new filtered wifi data set based on the chosen buildings
wifidata2{h} = wifidata(wifidata.Building == string(building_name_wifi(h)),:);


% finds the new number of areas where wifi count is detected 
G = findgroups(wifidata2{h}.Building, wifidata2{h}.Floor);  
numberofareas = max(G);

% creates a cell that contains the indidual columns of data for each area
areas = splitapply( @(varargin) varargin, wifidata2{h}, G);

% creates a cell that contains all of the information for each cell
Width = width(wifidata2{h});
        
for i = 1:numberofareas
    for j = 1:Width
        area{h,i}(:,j) = table(areas{i,j});
    end
end

% assigns the appropraiate variable names to all of the area tables
for i = 1:numberofareas
area{h, i}.Properties.VariableNames{1} = 'time';
area{h, i}.Properties.VariableNames{2} = 'EventTime';
area{h, i}.Properties.VariableNames{3} = 'AssociatedClientCount';
area{h, i}.Properties.VariableNames{4} = 'AuthenticatedClientCount';
area{h, i}.Properties.VariableNames{5} = 'Uni';
area{h, i}.Properties.VariableNames{6} = 'Building';
area{h, i}.Properties.VariableNames{7} = 'Floor';
area{h, i}.Properties.VariableNames{8} = 'Daynumber';
area{h, i}.Properties.VariableNames{9} = 'Timeofday';
end

  end

%% BMS Data Extraction 

    if got_bms == 1
      

% filter for specific building - once I have list of buildings, add all of them here 
BMS_data2{h} = BMS_data(BMS_data.tua_string == building_names_BMS(h),:);

% sort order of time 
BMS_data2{h} = sortrows(BMS_data2{h},{'name','timestamp'},'ascend');

% obtains the "day number" and " time of day" for each timestamp
DayNumber = weekday(BMS_data2{h}.timestamp); 
timeofDay = timeofday(BMS_data2{h}.timestamp);
 
BMS_data2{h}.Daynumber = DayNumber;
BMS_data2{h}.Timeofday = timeofDay;


G = findgroups(BMS_data2{h}.name);  
numberofmeasures = max(G);
measurements = splitapply( @(varargin) varargin, BMS_data2{h}, G);
Width = width(BMS_data2{h});
        

for i = 1:numberofmeasures
    for j = 1:Width
        measurement{h,i}(:,j) = table(measurements{i,j});
    end
end


for i = 1:numberofmeasures
measurement{h, i}.Properties.VariableNames{1} = 'device_id';
measurement{h, i}.Properties.VariableNames{2} = 'tua_string';
measurement{h, i}.Properties.VariableNames{3} = 'units';
measurement{h, i}.Properties.VariableNames{4} = 'key';
measurement{h, i}.Properties.VariableNames{5} = 'name';
measurement{h, i}.Properties.VariableNames{6} = 'BuildingName';
measurement{h, i}.Properties.VariableNames{7} = 'param_value';
measurement{h, i}.Properties.VariableNames{8} = 'timestamp';
measurement{h, i}.Properties.VariableNames{9} = 'Daynumber';
measurement{h, i}.Properties.VariableNames{10} = 'Timeofday';

end


    end

%% SYNETICA - Relevant Data Extraction

if got_synetica == 1

% creates a new filtered set of synetica data
joinedData2{h} = joinedData(joinedData.serving_revised == string(building_name_synetica(h)) ,:);

% finds the new number of meters in the data 
G = findgroups(joinedData2{h}.name);  
numberofmeters = max(G);

% creates a cell that contains the indidual columns of data for each meter
meters = splitapply( @(varargin) varargin, joinedData2{h}, G);

% calculates the number of columns in the data 
Width = width(joinedData2{h});

% creates a cell that contains all of the information for each cell 
for i = 1:numberofmeters
    for j = 1:Width
        meter{h,i}(:,j) = table(meters{i,j});
    end
end  


% assigns the appropraiet variable names to all of the meter tables

for i = 1:numberofmeters
meter{h, i}.Properties.VariableNames{1} = 'name';
meter{h, i}.Properties.VariableNames{2} = 'MeterType';
meter{h, i}.Properties.VariableNames{3} = 'Serving';
meter{h, i}.Properties.VariableNames{4} = 'serving_revised';
meter{h, i}.Properties.VariableNames{5} = 'class';
meter{h, i}.Properties.VariableNames{6} = 'units_after_conversion';
meter{h, i}.Properties.VariableNames{7} = 'timestamp';
meter{h, i}.Properties.VariableNames{8} = 'device_id';
meter{h, i}.Properties.VariableNames{9} = 'reading';
meter{h, i}.Properties.VariableNames{10} = 'units';
meter{h, i}.Properties.VariableNames{11} = 'DayNumber';
meter{h, i}.Properties.VariableNames{12} = 'Timeofday';

end

for i = 1:numberofmeters
TT{h,i} = table2timetable(meter{h,i});
TT{h,i} = sortrows(TT{h, i},'timestamp','ascend');
TT{h,i} = retime(TT{h,i},'regular', 'fillwithmissing','TimeStep',minutes(10));

end

% converts the timetable back to a table
for i = 1:numberofmeters
meter2{h,i} = timetable2table(TT{h,i});
end

% Converts cumulative meters to rate 
for i = 1:numberofmeters
    if meter2{h,i}.class(1) == "Cumulative"
        meter2{h,i}.reading(1:end-1) = diff(meter2{h,i}.reading);
        meter2{h,i}.reading(end) = meter2{h,i}.reading(end-1);
         for j = 1:height(meter2{h,i})
              if meter2{h,i}.reading(j) < 0 
              meter2{h,i}.reading(j) = 0;
              end
         end
        meter2{h,i}.reading = filloutliers(meter2{h,i}.reading,'previous', 'movmedian', 9);
    end
end

%meter2 = meter2(~cellfun('isempty',meter2));

end


%% Wifi Joining

if got_wifi == 1

% calculates the number of meters in building h 
 idx3=sum(~cellfun(@isempty,area),2);

 numberofareas = idx3(h);

for i = 1:numberofareas
    % isolate just the columns that contain numerical info and timestamp - 'retime' doesn't work otherwise 
wifi_timetable{h,i} = area{h,i}(:, {'time', 'AssociatedClientCount'});

% convert filtered table into a timetable
wifi_timetable{h,i} = table2timetable(wifi_timetable{h,i}); 

% use 'retime' to adjust the timestamp to regular values, with 5 minute timestep and interpolate values to fit to the new timestamps 
wifi_timetable{h,i} = unique(wifi_timetable{h,i});
wifi_timetable{h,i} = rmmissing(wifi_timetable{h,i}); 
wifi_timetable{h,i} = retime(wifi_timetable{h,i}, 'regular', 'linear', 'TimeStep', minutes(5));

% isolate only one out of the two months of data - 
S = timerange(wifi_timetable{h,i}.time(1),'months');
wifi_timetable{h,i} = wifi_timetable{h,i}(S,:);
end

% assigns appropriate variable names to timetables
for i = 1:numberofareas
str(h,i) = append( string(area{h,i}.Building(1)),'-', string(area{h,i}.Floor(1))); 
end
% 'Wifi Device Count - ',

for i = 1:numberofareas
wifi_timetable{h,i}.Properties.VariableNames{1} = str{h,i}; 
end

% assigns the timetable for the first area as the the first column in the complete timetable 
wifi_timetable_complete{h} = wifi_timetable{h,1};

% adds the rest of of the timetables to the complete timetable
for i = 2:numberofareas
    % wifi_timetable_complete{h} = [wifi_timetable_complete{h} wifi_timetable{h,i}];
    wifi_timetable_complete{h} = synchronize(wifi_timetable_complete{h}, wifi_timetable{h,i});
end

end
%% BMS Joining

if got_bms == 1

% repeated for bms data, but makes the timetamp regualar 10 minute intervals

idx=sum(~cellfun(@isempty,measurement),2);
n = idx(h);

for i = 1:n
 

measurement{h, i} = rmmissing(measurement{h, i});
bms_timetable{h,i} = measurement{h,i}(:,7:8); 
bms_timetable{h,i} = table2timetable(bms_timetable{h,i});
bms_timetable{h,i} = retime(bms_timetable{h,i}, 'regular', 'pchip', 'TimeStep', minutes(10));

end

for i = 1:n
str2(h,i) = append('BMS Measurement - ', string(measurement{h,i}.name(1)),'(DegC)'); % add 'device count' to this 
end

for i = 1:n
bms_timetable{h,i}.Properties.VariableNames{1} = str2{h,i}; 
end

bms_timetable_complete{h} = bms_timetable{h,1};

for i = 2:n
    bms_timetable_complete{h} = [bms_timetable_complete{h} bms_timetable{h,i}];
end

end

 %% Synetica joining
 
 if got_synetica == 1
     
     % find number of meters for building h
 
 idx2=sum(~cellfun(@isempty,meter2),2);

 numberofmeters = idx2(h);
 
for i = 1:numberofmeters
    % isolate just the columns that contain numerical info and timestamp - 'retime' doesn't work otherwise 
synetica_timetable{h,i} = meter2{h,i}(:, {'timestamp', 'reading'});

% convert filtered table into a timetable
synetica_timetable{h,i} = table2timetable(synetica_timetable{h,i});
synetica_timetable{h,i} = unique(synetica_timetable{h,i});
synetica_timetable{h,i} = rmmissing(synetica_timetable{h,i}); 
synetica_timetable{h,i} = retime(synetica_timetable{h,i}, 'regular', 'linear', 'TimeStep', minutes(5));
un_numofdatapoints(i,1) = height(synetica_timetable{h,i});
count{i,h}(1) = 0;

  n = height(synetica_timetable{1,i});
  for j = 2:n
        t1 = datevec(synetica_timetable{h,i}.timestamp(j));
        t2 = datevec(synetica_timetable{h,i}.timestamp(j-1));
        time_interval(j-1) = (etime(t1,t2))/60;
        if time_interval(j-1) > 12
            count{i,h}(j-1) = fix(time_interval(j-1)/10);
        end
    end


end

% assigns appropriate variable names to timetables, depending on the length
% 
for i = 1:numberofmeters
    
   
   if strlength(append(string(meter2{h,i}.serving_revised(1)),string(meter2{h,i}.Serving(1)))) < 63
     
      str3(h,i) = append(string(meter2{h,i}.serving_revised(1)),string(meter2{h,i}.Serving(1))); %'(', string(meter2{h,i}.units_after_conversion(1)), ')'); % add 'device count' to this 
   else 
       str3(h,i) = string(meter2{h,i}.Serving(1));
   end
   end

for i = 1:numberofmeters
synetica_timetable{h,i}.Properties.VariableNames{1} = str3{h,i}; 
end

% assigns the timetable for the first area as the the first column in the complete timetable
synetica_timetable_complete{h} = synetica_timetable{h,1};

% adds the rest of the meters to the complete timetable
for i = 2:numberofmeters
   % synetica_timetable_complete{h} = [synetica_timetable_complete{h} synetica_timetable{h,i}];
    synetica_timetable_complete{h} = synchronize(synetica_timetable_complete{h}, synetica_timetable{h,i},'union','previous');
end

% ensures that rows are sorted in chonological order
synetica_timetable_complete{h} = sortrows(synetica_timetable_complete{h},'timestamp','ascend');

 end

%% Combine all datasets 

% creates a synchronised timetable that interpolates bms data to fit in with the 5 minute wifi timestamps so both datasets have a common timestamp

if got_wifi == 1 && got_bms == 1 && got_synetica == 1
    synch_TT{h} = synchronize(wifi_timetable_complete{h} ,synetica_timetable_complete{h},bms_timetable_complete{h},weatherdata,'union','previous');
elseif got_wifi == 1 && got_bms == 1
    synch_TT{h} = synchronize(wifi_timetable_complete{h} ,bms_timetable_complete{h},weatherdata,'union','previous');
elseif  got_wifi == 1 && got_synetica == 1
    synch_TT{h} = synchronize(wifi_timetable_complete{h} ,synetica_timetable_complete{h},'union','previous');
elseif got_synetica == 1 && got_bms == 1
    synch_TT{h} = synchronize(bms_timetable_complete{h},synetica_timetable_complete{h},weatherdata,'union','previous');
elseif got_wifi == 1
    synch_TT{h} = synchronize(wifi_timetable_complete{h},'union','previous');
elseif got_bms == 1
    synch_TT{h} = synchronize(bms_timetable_complete{h},weatherdata,'union','previous');
elseif got_synetica == 1
    synch_TT{h} = synchronize(synetica_timetable_complete{h},'union','previous');
end
    
    % converts timetable back to table
buildingname_data{h} = timetable2table(synch_TT{h});




%% Average weekday and weekend profile 

DayNumber = weekday(buildingname_data{h}.time); 
timeofDay = timeofday(buildingname_data{h}.time);
WeekEnd = isweekend(buildingname_data{h}.time);

buildingname_data{h}.Daynumber = DayNumber;
buildingname_data{h}.Timeofday = timeofDay;
buildingname_data{h}.Weekend = WeekEnd;

% finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
groups = findgroups(buildingname_data{h}.Weekend, buildingname_data{h}.Timeofday);

% adds the groups as a variable to each table in the cell
buildingname_data{h}.group = groups;
l = height(buildingname_data{h});

% constructs a time variable for plotting purposes
time1 = datetime(2018,1,1,0,0,0);
time2 = datetime(2018,1,1,23,55,0);
time = time1:minutes(5):time2;

for i = 2:width(buildingname_data{h})-4
   
    reading = buildingname_data{h}.Properties.VariableNames{i};
    
    % creates a variable that describes the smoothed, normalised weekday and weekend daily profile for reading i 
    Weekday_reading{h,i} = groupsummary(buildingname_data{h},{'group'},'mean',reading,'IncludeMissingGroups',false);
    Weekday_reading{h,i}.Properties.VariableNames{3} = 'Average_Reading';
    
    
    % plots the average weekday and weekend profile for reading i 
    figure()
    plot(time, movavg(filloutliers(Weekday_reading{h,i}.Average_Reading(1:288),'previous'),'simple',20))
    hold on
    plot(time,movavg(filloutliers(Weekday_reading{h,i}.Average_Reading(289:end),'previous'),'simple',20))
    legend('Weekday', 'Weekend')
    xlabel('Time')
    ylabel('Energy Consumption')
    title(['Average Daily Profile for -'  buildingname_data{h}.Properties.VariableNames{i}])
    
    % creates the normalised and non-normalised average weekday and weekend
    % profile for meter i of building h 
    avg_weekday_norm{i,h}= normalize(movavg(filloutliers(Weekday_reading{h,i}.Average_Reading(1:288),'previous'),'simple',20),'range');
    avg_weekday{i,h}= movavg(filloutliers(Weekday_reading{h,i}.Average_Reading(1:288),'previous'),'simple',20);
    avg_weekday_norm{i,h}(isnan(avg_weekday_norm{i,h})) = 0;
     avg_weekday{i,h}(isnan(avg_weekday{i,h})) = 0;
    avg_weekday{i,h} = table(avg_weekday{i,h}(:,1));
    avg_weekday{i,h}.Properties.VariableNames{1} = buildingname_data{h}.Properties.VariableNames{i};
   
    avg_weekend_norm{i,h} = normalize(movavg(filloutliers(Weekday_reading{h,i}.Average_Reading(289:end),'previous'),'simple',20),'range');
    avg_weekend{i,h} = movavg(filloutliers(Weekday_reading{h,i}.Average_Reading(289:end),'previous'),'simple',20);
     avg_weekend_norm{i,h}(isnan(avg_weekend_norm{i,h})) = 0;
      avg_weekend{i,h}(isnan(avg_weekend{i,h})) = 0;
    avg_weekend{i,h} = table(avg_weekend{i,h}(:,1));
    avg_weekend{i,h}.Properties.VariableNames{1} = buildingname_data{h}.Properties.VariableNames{i};

    
end
    
%% energy per person


if got_synetica == 1 && got_wifi == 1
    
    % obtains total wifi device count for building h 
    wifi_sum{h} = table2array(avg_weekday{2,h});
    
    for j = 3:width(timetable2table(wifi_timetable_complete{h}))
        wifi_sum{h} = wifi_sum{h} + table2array(avg_weekday{j,h});
    end
    
   % obtains energy per person for each meter
    for j = width(wifi_timetable_complete{h})+2:width(synetica_timetable_complete{h})+width(wifi_timetable_complete{h})+1
       
        energy_per_person{h,j} = table(trapz(table2array(avg_weekday{j,h}))/trapz(wifi_sum{h}));
        energy_per_person{h,j}.Properties.VariableNames{1} = avg_weekday{j,h}.Properties.VariableNames{1};
        energy_per_person{h,j};
        
        
    end
end

%% classification Energy (and pie chart for energy distribution)

if got_synetica == 1 && Metertype == "Electricity"

load('elec_class_net.mat')

% locates the start and ending index in combined list of meters for
% sysnetica meters only 
synet_start = width(timetable2table(wifi_timetable_complete{h}))+1;

synet_end = synet_start + width(synetica_timetable_complete{h}) - 1;

% creates two new variables for classification and comparison purposes 
synet_classify_data = avg_weekday_norm(synet_start:synet_end,h);
synet_data = avg_weekday(synet_start:synet_end,h);

for i = 1:length(synet_data)
    synet_data{i} = table2array( synet_data{i});
end
% 
for i= 1:length(synet_classify_data)
synet_classify_data{i} = synet_classify_data{i}';
end

% imports trained lstm model and classifies each synetica meter 
miniBatchSize = 48;

YPred_elec{h} = classify(elec_class_net,synet_classify_data, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');

YPred_elec{h} = string(YPred_elec{h});

YPred_elec{h}(ismissing(YPred_elec{h})) = "Unidentifiable";

numClasses_elec = length(unique(YPred_elec{h}));

classes_elec = string(unique(YPred_elec{h}));


classes_elec(ismissing(classes_elec)) = "Unidentifiable";

building_name_elec(1:length(YPred_elec{h}),1) = building_name_synetica(h);

for i = 1:length(YPred_elec{h})
    meter_description(i,1) = meter{h,i}.Serving(1);
end

% creates table to compare classification of each meter
classify_verify_elec{h} = table(YPred_elec{h},building_name_elec,meter_description, synet_classify_data,synet_data);

% splits classes of meters and plots as pie chart

   for n = 1:numClasses_elec
     for j = 1:height(classify_verify_elec{h})
         if classify_verify_elec{h}.Var1(j) == classes_elec(n)
             type_classify_elec{1,n}(j,:) = classify_verify_elec{h}(j,:);  
         end
     end   
 end
 
  for n = 1:numClasses_elec
      type_classify_elec{1,n} = type_classify_elec{1,n}(~ismissing(type_classify_elec{1,n}.Var1),:);
  end



for n = 1:numClasses_elec
    build_type_total_elec{h}(n) = trapz(cell2mat(type_classify_elec{n}.Var5(1)));
    for i = 2:height(type_classify_elec{n})
        build_type_total_elec{h}(n) = build_type_total_elec{h}(n) + trapz(cell2mat(type_classify_elec{n}.Var5(i)));
    end
end



% Creates pie chart showing fraction of building types the building illustrates
figure()
pie(build_type_total_elec{h})
legend([classes_elec])
title(['Pie Chart to Illustrate the Building Type Distribution within - ' building_name_wifi(h)])

% end

 % repeats for water 
if got_synetica == 1 && Metertype == "Water"

load('water_class_net.mat')

synet_start = width(timetable2table(wifi_timetable_complete{h}))+1;

synet_end = synet_start + width(synetica_timetable_complete{h}) - 1;

synet_classify_data = avg_weekday_norm(synet_start:synet_end,h);
synet_data = avg_weekday(synet_start:synet_end,h);

for i = 1:length(synet_data)
    synet_data{i} = table2array( synet_data{i});
end
% 
for i= 1:length(synet_classify_data)
synet_classify_data{i} = synet_classify_data{i}';
end

miniBatchSize = 48;

YPred_water{h} = classify(water_class_net,synet_classify_data, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');

YPred_water{h} = string(YPred_water{h});

YPred_water{h}(ismissing(YPred_water{h})) = "Unidentifiable";

numClasses_water = length(unique(YPred_water{h}));

classes_water = string(unique(YPred_water{h}));


classes_water(ismissing(classes_water)) = "Unidentifiable";

building_name_water(1:length(YPred_water{h}),1) = building_name_synetica(h);

for i = 1:length(YPred_water{h})
    meter_description(i,1) = meter{h,i}.Serving(1);
end


classify_verify_water{h} = table(YPred_water{h},building_name_water,meter_description, synet_classify_data,synet_data);


   for n = 1:numClasses_water
     for j = 1:height(classify_verify_water{h})
         if classify_verify_water{h}.Var1(j) == classes_water(n)
             type_classify_water{1,n}(j,:) = classify_verify_water{h}(j,:);  
         end
     end   
 end
 
  for n = 1:numClasses_water
      type_classify_water{1,n} = type_classify_water{1,n}(~ismissing(type_classify_water{1,n}.Var1),:);
  end

  
  
for n = 1:numClasses_water
    build_type_total_water{h}(n) = trapz(cell2mat(type_classify_water{n}.Var5(1)));
    for i = 2:height(type_classify_water{n})
        build_type_total_water{h}(n) = build_type_total_water{h}(n) + trapz(cell2mat(type_classify_water{n}.Var5(i)));
    end
end



% Creates pie chart showing fraction of building types the building illustrates
figure()
pie(build_type_total_water{h})
legend([classes_water])
title(['Pie Chart to Illustrate the Building Type Distribution within - ' building_name_wifi(h)])

end
%% Classify Wi_Fi

% repeats for wifi 

if got_wifi == 1

load('wifi_class_net.mat')

wifi_classify_data = avg_weekday_norm(2:width(timetable2table(wifi_timetable_complete{h})),h);
wifi_data = avg_weekday(2:width(timetable2table(wifi_timetable_complete{h})),h);

for i = 1:length(wifi_data)
    wifi_data{i} = table2array( wifi_data{i});
end

for i= 1:length(wifi_classify_data)
wifi_classify_data{i} = wifi_classify_data{i}';
end

miniBatchSize = 48;

YPred{h} = classify(wifi_class_net,wifi_classify_data, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');

YPred{h} = string(YPred{h});

YPred{h}(ismissing(YPred{h})) = "Unidentifiable";

numClasses = length(unique(YPred{h}));

classes = string(unique(YPred{h}));


classes(ismissing(classes)) = "Unidentifiable";

building_name{h}(1:length(YPred{h}),1) = building_name_wifi(h);

for i = 1:length(YPred{h})
    Floor{h}(i,1) = area{h,i}.Floor(1);
end

% NEED TO CHANGE
classify_verify{h} = table(YPred{h},building_name{h},Floor{h}, wifi_classify_data,wifi_data);


   for n = 1:numClasses
     for j = 1:height(classify_verify{h})
         if classify_verify{h}.Var1(j) == classes(n)
             type_classify{1,n}(j,:) = classify_verify{h}(j,:);  
         end
     end   
 end
 
  for n = 1:numClasses
      type_classify{1,n} = type_classify{1,n}(~ismissing(type_classify{1,n}.Var1),:);
  end



for n = 1:numClasses
    build_type_total{h}(n) = trapz(cell2mat(type_classify{n}.Var5(1)));
    for i = 2:height(type_classify{n})
        build_type_total{h}(n) = build_type_total{h}(n) + trapz(cell2mat(type_classify{n}.Var5(i)));
    end
end



% Creates pie chart showing fraction of building types the building illustrates
figure()
pie(build_type_total{h})
legend([classes])
title(['Pie Chart to Illustrate the Building Type Distribution within - ' building_name_wifi(h)])

end

%% Export to Excel

if excel == "yes"
    if compile == "yes"
   
    % reads the file to write to, to interpret which cell to start to export the data to
    
    buildingdata = readtable(filenAme, 'Sheet', string(building_name_synetica(h)));
    length = size(buildingdata,1);
    range = ['A',num2str(length+1)];
    
    % exports the data into a excel file, with a different building for each sheet
    writetable(buildingname_data{h},filenAme,'WriteVariableNames', false,'Range',range, 'Sheet', string(building_name_synetica(h)));
    
    else
        % writes data to fresh excel file with specified name
        writetable(buildingname_data{h},filenAme,'WriteVariableNames', true, 'Sheet', string(building_name_synetica(h)));
    end
end




%% Evaluate Quality of the Data Synetica

% comprehend the month of the year to obtain the expeted number of data
% points 

theMonth = month(joinedData.timestamp(1));
theYear = year(joinedData.timestamp(1));

if theMonth==1||theMonth==3||theMonth==5||theMonth==7||theMonth==8||theMonth==10||theMonth==12
    no_daysinmonth = 31;
elseif theMonth==4||theMonth==6||theMonth==9||theMonth==11
    no_daysinmonth = 30;
elseif theMonth == 2 && mod(theYear,4) == 0
    no_daysinmonth = 29;
else
    no_daysinmonth = 28;
end

% expected number of data points

theo_numbofdatapoints = 288* no_daysinmonth;

for i = 1:numberofmeters
    x{h}(i,1) = string(meter{h,i}.name(1));
    data_percent(i,h) = (un_numofdatapoints(i,h)/theo_numbofdatapoints)*100;
    
end

x{h}(:,2) = data_percent(:,h);

clear data_percent

data_quality_synet = x;


meter3 = meter2;

% number of meters in building h
idx5=sum(~cellfun(@isempty,meter2),2);
numberofmeters = idx2(h);

% deduces data quality class

% F class

for i = 1:numberofmeters
    if mean(meter2{h,i}.reading) < 1e-04
        data_quality_synet{h}(i,3) = meter2{h,i}.serving_revised(1);
        data_quality_synet{h}(i,4) = meter2{h,i}.Serving(1);
        data_quality_synet{h}(i,5) = {'F'};
        meter3{h,i} = [];
    end
end



% E class

for i = 1:numberofmeters
    if isempty(meter3{h,i}) == 0
        for n = 1:7
            for j = 1:height(meter{h,i})
                if meter{h,i}.DayNumber(j) == n
                    match = n;
                end
            end
        end
        if match ~= 7
            data_quality_synet{h}(i,3) = meter{h,i}.serving_revised(1);
            data_quality_synet{h}(i,4) = meter{h,i}.Serving(1);
            data_quality_synet{h}(i,5) = {'E'};
            meter3{i} = [];
        end
    end
end



% D class

for i = 1:numberofmeters
    if isempty(meter3{h,i}) ~= 1
        if length(unique(meter3{i}.reading)) < 4
            data_quality_synet(i,3) = meter{i}.serving_revised(1);
            data_quality_synet(i,4) = meter{i}.Serving(1);
            data_quality_synet(i,5) = {'D'};
            meter3{h,i} = [];
        end
    end
end



% C class

for i = numberofmeters
    if isempty(meter3{i}) ~= 1
        if length(count{i,h})/height(meter2{h,i}) > 0.3 
            data_quality_synet{h}(i,3) = meter{i}.serving_revised(1);
            data_quality_synet{h}(i,4) = meter{i}.Serving(1);
            data_quality_synet{h}(i,5) = {'C'};
            meter3{h,i} = [];
        end
    end
end



% B class

for i = numberofmeters
    if isempty(meter3{h,i}) == 0
        if height(meter2{h,i}) ~= height(meter{h,i})
            data_quality_synet{h}(i,3) = meter{h,i}.serving_revised(1);
            data_quality_synet{h}(i,4) = meter{h,i}.Serving(1);
            data_quality_synet{h}(i,5) = {'B'};
            meter3{h,i} = [];
        end
    end
end


% A class

for i = 1:numberofmeters
    if isempty(meter3{h,i}) == 0
        test = 5;
        data_quality_synet{h}(i,3) = meter3{h,i}.serving_revised(1);
        data_quality_synet{h}(i,4) = meter3{h,i}.Serving(1);
        data_quality_synet{h}(i,5) = {'A'};
    else
        test = 6;
    
    end
end



end


 



    
end