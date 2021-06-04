%% BMS Data Analysis

% THIS SCRIPT IS TO SEPARATE THE BMS DATA READINGS AND PLOT THEM

clear variables

%% Import the Data

bms_rawdata = [];% IMPORT RAW BMS DATA FILE E.G readtable('C:\Users\charl\AppData\Local\Temp\bms-jan-2020.csv'); % import raw data table

bms_rawdata.device_id = categorical(bms_rawdata.device_id);


%% Filter and Join Raw Data


bms_rawdata = removevars(bms_rawdata, {'param_name','param_type'}); %remove unwanted variables

bms_rawdata.Properties.VariableNames{4} = 'key'; % change variable to match other datasets


% joins the two different metadata datasets 
bmsmetadata = []; % INSERT METADATA FILE IN THS FILE readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\bmsmetadata.xlsx'); 

bmsmetadata.device_id = categorical(bmsmetadata.device_id);


% join raw data and new metadata table to get table with wanted variables 
BMS_data = innerjoin(bmsmetadata,bms_rawdata,'Keys',{'device_id','key'});

% filter for data where only measured in degrees 
% BMS_data = BMS_data(ismember(BMS_data.units,{'DEGC','DegC','Deg'}),:);


% sort order of time 
BMS_data = sortrows(BMS_data,{'name','timestamp'},'ascend');

% separates meters 

G = findgroups(BMS_data.name);  
numberofmeasures = max(G);

G = findgroups(BMS_data.name);  
numberofmeasures = max(G);
measurements = splitapply( @(varargin) varargin, BMS_data, G);
Width = width(BMS_data);
        

for i = 1:numberofmeasures
    for j = 1:Width
        measurement{i}(:,j) = table(measurements{i,j});
    end
end

% ensures variable names are as expected 

for i = 1:numberofmeasures
measurement{1, i}.Properties.VariableNames{1} = 'device_id';
measurement{1, i}.Properties.VariableNames{2} = 'tua_string';
measurement{1, i}.Properties.VariableNames{3} = 'units';
measurement{1, i}.Properties.VariableNames{4} = 'key';
measurement{1, i}.Properties.VariableNames{5} = 'name';
measurement{1, i}.Properties.VariableNames{6} = 'param_value';
measurement{1, i}.Properties.VariableNames{7} = 'timestamp';
measurement{1, i}.Properties.VariableNames{8} = 'Daynumber';
measurement{1, i}.Properties.VariableNames{9} = 'Timeofday';

end


% Plots each meter 
     
for j = 1:numberofmeasures
    figure()
    plot(measurement{1,j}.timestamp, measurement{1,j}.param_value);
    xlabel('Time')
    ylabel(measurement{1,j}.units(1))
    title(string(measurement{1,j}.tua_string(1)) + "-" + string(measurement{1,j}.name(1)))   
end   

