%% Synetica Meter Analysis 

% THIS SCRIPT IS TO BE USED TO UPDATE THE SYNETICA CHECKLIST, plot average
% daily profiles of each meter and observe the distribution of electricity
% consumption between building types 

clear all

%% SYNETICA - Extract relevent Synetica Data 

classIfy = input('Want to classify? ("yes" or "no")');

raw_datafile = []; % INSERT SYNET DATA FILE E.G'C:\Users\charl\AppData\Local\Temp\synetica-apr-2018.csv';
 


% ensures the specified variables are of type 'categorical'
opts = detectImportOptions(raw_datafile);
opts = setvartype(opts,{'name','units', 'device_id'},'categorical');
               
% import raw synetica data for chosen month 
SyneticaData = readtable(raw_datafile); %imports synetica file chosen by user

opts = detectImportOptions('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica_meter_list_210122.xlsx');
opts = setvartype(opts,{'MeterID','MeterType', 'serving_revised','class','units_after_conversion'},'categorical');

% import the synetica meter list
Syneticameterlist = readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica_meter_list_210122.xlsx');

Syneticameterlist.Properties.VariableNames{1} = 'name';

if classIfy == "yes"
  Syneticameterlist = Syneticameterlist(Syneticameterlist.MeterType == "Electricity",:);
end
    

%% SYNETICA - Join Datasets 

% ensures meters with no 'class' defined' have a definition of 'not defined'
Syneticameterlist.class = fillmissing(Syneticameterlist.class, 'constant', 'not defined');

% use innerjoin the combine the appropriatley filtered meter list with the syentica data for the chosen month 
joinedData = innerjoin(Syneticameterlist,SyneticaData,'Keys',{'name'});

% add the 'day number' and 'time of day' (HH:MM:SS) to the new data table
DayNumber = weekday(joinedData.timestamp); 
timeofDay = timeofday(joinedData.timestamp);
 
joinedData.Daynumber = DayNumber;
joinedData.Timeofday = timeofDay;

%% split data into individual meters

G = findgroups(joinedData.name);  
numberofmeters = max(G);
meters = splitapply( @(varargin) varargin, joinedData, G);
Width = width(joinedData);
        

for i = 1:numberofmeters
    for j = 1:Width
        meter{i}(:,j) = table(meters{i,j});
    end
end


for i = 1:numberofmeters
    meter{1, i}.Properties.VariableNames{1} = 'name';
    meter{1, i}.Properties.VariableNames{2} = 'MeterType';
    meter{1, i}.Properties.VariableNames{3} = 'Serving';
    meter{1, i}.Properties.VariableNames{4} = 'serving_revised';
    meter{1, i}.Properties.VariableNames{5} = 'class';
    meter{1, i}.Properties.VariableNames{6} = 'units_after_conversion';
    meter{1, i}.Properties.VariableNames{7} = 'timestamp';
    meter{1, i}.Properties.VariableNames{8} = 'device_id';
    meter{1, i}.Properties.VariableNames{9} = 'reading';
    meter{1, i}.Properties.VariableNames{10} = 'units';
    meter{1, i}.Properties.VariableNames{11} = 'DayNumber';
    meter{1, i}.Properties.VariableNames{12} = 'Timeofday';
        for j = 1:width(meter{1,i})
        if class(table2array(meter{1,i}(1,j))) ~= "double"
            if table2array(meter{1,i}(1,j)) == "" 
                meter{1,i}(:,j) = {'empty'};
            elseif ismissing(table2array(meter{1,i}(1,j))) == 1 
                meter{1,i}(:,j) = {'empty'};
            end
        
        end
    end
end

%% %% Average Daily Profile for each meter for this particular month

% fill out any missing parts to data

numberofmeters = length(meter);

for i = 1:length(meter)
TT{1,i} = table2timetable(meter{1,i});
TT{1,i} = sortrows(TT{1, i},'timestamp','ascend');
TT{1,i} = unique(TT{1,i});
TT{1,i} = rmmissing(TT{1,i});
TT{1,i} = retime(TT{1,i},'regular', 'previous','TimeStep',minutes(10));
end


% converts the timetable back to a table
for i = 1:length(meter)
meter2{1,i} = timetable2table(TT{1,i});
end


% fills out missing data points, configures average daily profile for a
% weekday and for weekend that is normalised and smoothed out 

 for i = 1:length(meter)
      DayNumber = weekday(meter2{1,i}.timestamp); 
 timeofDay = timeofday(meter2{1,i}.timestamp);
 WeekEnd = isweekend(meter2{1,i}.timestamp);
 
 meter2{1,i}.Weekend = WeekEnd;
 meter2{1,i}.Timeofday = timeofDay;
 
 % finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
 groups = findgroups(meter2{1,i}.Weekend, meter2{1,i}.Timeofday);
 
 % adds the groups as a variable to each table in the cell
 meter2{1,i}.group = groups;
 l = height(meter2{1,i});
 
 % constructs a time variable for plotting purposes
 time1 = datetime(2018,1,1,0,0,0);
 time2 = datetime(2018,1,1,23,50,0);
 time = time1:minutes(10):time2;
 
% creates a variable that describes both the weekday and weekend avg daily profile
 Weekday = groupsummary(meter2{1,i},{'group'},'mean','reading','IncludeMissingGroups',false);
 Weekday.Properties.VariableNames{3} = 'Average_Reading';
 
% plots average weekday and weekend profile for each meter 
%  figure(i)  
%  plot(time, Weekday.Average_Reading(1:144))
%  xlabel('Time')
%  ylabel('Energy Consumption')
%  title(['Average Daily Profile for'  meter2{1,i}.serving_revised(1)  '-'  meter2{1,i}.Serving(1)])
%     
 
% creates average normalised and non normalsied average weekday and weekend
% profiles 
avg_weekday_norm{i,1} = normalize(movavg(Weekday.Average_Reading(1:144),'simple',20),'range');
avg_weekday{i,1} = movavg(Weekday.Average_Reading(1:144),'simple',20);

avg_weekend_norm{i,1} = normalize(movavg(Weekday.Average_Reading(145:end),'simple',20),'range');
avg_weekend{i,1} = movavg(Weekday.Average_Reading(145:end),'simple',20);

 end



%% calculates amount of data available as fraction (percentage) of the theoretical number of data points


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

theo_numbofdatapoints = 144* no_daysinmonth;


for i = 1:length(meter)
    synetica_timetable{1,i} = meter{1,i}(:, {'timestamp', 'reading'});
    synetica_timetable{1,i} = table2timetable(synetica_timetable{1,i});
    synetica_timetable{1,i} = sortrows(synetica_timetable{1,i},'timestamp','ascend');
    synetica_timetable{1,i} = unique(synetica_timetable{1,i});
    synetica_timetable{1,i} = rmmissing(synetica_timetable{1,i});
    synetica_timetable{1,i} = timetable2table(synetica_timetable{1,i});
    un_numofdatapoints(i,1) = height(synetica_timetable{1,i});
    count{i,1}(1) = 0;
    n = height(synetica_timetable{1,i});
    
    for j = 2:n
        t1 = datevec(synetica_timetable{1,i}.timestamp(j));
        t2 = datevec(synetica_timetable{1,i}.timestamp(j-1));
        time_interval(j-1) = (etime(t1,t2))/60;
        if time_interval(j-1) > 12
            count{i,1}(j-1) = round(time_interval(j-1)/10);
        end
    end
    
    count{i,1} = nonzeros(count{i,1});
    
    meter2{1,i} = synetica_timetable{1,i};
    meter2{1,i}(:,3) = table(meter{1,i}.device_id(1));
    meter2{1,i}(:,4) = table(meter{1,i}.serving_revised(1));
    meter2{1,i}(:,5) = table(meter{1,i}.Serving(1));
    meter2{1,i}(:,6) = table(meter{1,i}.name(1));
    meter2{1,i}(:,7) = table(meter{1,i}.class(1));
    meter2{1, i}.Properties.VariableNames{3} = 'device_id';
    meter2{1, i}.Properties.VariableNames{4} = 'serving_revised';
    meter2{1, i}.Properties.VariableNames{5} = 'Serving';
    meter2{1, i}.Properties.VariableNames{6} = 'name';
    meter2{1, i}.Properties.VariableNames{7} = 'class';
    
    
end

% deduce data quantity

for i = 1:length(meter)
    x(i,1) = string(meter{1,i}.name(1));
    data_percent(i,1) = (un_numofdatapoints(i)/theo_numbofdatapoints)*100;
    
end

x(:,2) = data_percent(:,1);

clear data_percent

data_percent = x;

%% Convert Cumulative to Rate 

for i = 1:numberofmeters
    if meter2{1,i}.class(1) == "Cumulative"
        meter2{1,i}.reading(1:end-1) = diff(meter2{1,i}.reading);
        meter2{1,i}.reading(end) = meter2{1,i}.reading(end-1);
        for j = 1:height(meter2{1,i})
            if meter2{1,i}.reading(j) < 0
                meter2{1,i}.reading(j) = 0;
            end
        end
        meter2{1,i}.reading = filloutliers(meter2{1,i}.reading,'previous', 'movmedian', 9);
    elseif string(meter2{1,i}.class(1)) == "not defined"
        
        Stats = zeros(1);
        Stats = table(Stats);
        
        load('Cumlative_or_Rate.mat')
        for j = 1:length(meter2{1,i})
            
            st_dev = std(table2array(meter2{1,j}.reading));
            Var = var(table2array(meter2{1,j}.reading));
            Mean = mean(table2array(meter2{1,j}.reading));
            Median = median(table2array(meter2{1,j}.reading));
            
            Stats_test.st_dev(j) = st_dev;
            Stats_test.Var(j) = Var;
            Stats_test.Mean(j) = Mean;
            Stats_test.Median(j) = Median;
            
        end
        yfit = Cumlative_or_Rate.predictFcn(Stats_test(:,3:end));
        
        meter2{1,i}.class(:) = string(yfit);
    end
        
end



%% Evaluate Quality of the Data

meter3 = meter2;

% deduce data quality class 

% F class

for i = 1:length(meter2)
    if mean(meter2{i}.reading) < 1e-04
        class(i,1) = meter2{i}.serving_revised(1);
        class(i,2) = meter2{i}.Serving(1);
        class(i,3) = {'F'};
        meter3{i} = [];
    end
end



% E class

for i = 1:length(meter3)
    if isempty(meter3{i}) == 0
        for n = 1:7
            for j = 1:height(meter{i})
                if meter{i}.DayNumber(j) == n
                    match = n;
                end
            end
        end
        if match ~= 7
            class(i,1) = meter{i}.serving_revised(1);
            class(i,2) = meter{i}.Serving(1);
            class(i,3) = {'E'};
            meter3{i} = [];
        end
    end
end



% D class

for i = 1:length(meter3)
    if isempty(meter3{i}) ~= 1
        if length(unique(meter3{i}.reading)) < 7
            class(i,1) = meter{i}.serving_revised(1);
            class(i,2) = meter{i}.Serving(1);
            class(i,3) = {'D'};
            meter3{i} = [];
        end
    end
end



% C class

for i = length(meter3)
    if isempty(meter3{i}) ~= 1
        if length(count{i})/height(meter2{i}) > 0.3 
            class(i,1) = meter{i}.serving_revised(1);
            class(i,2) = meter{i}.Serving(1);
            class(i,3) = {'C'};
            meter3{i} = [];
        end
    end
end



% B class

for i = length(meter2)
    if isempty(meter3{i}) == 0
        if height(meter2{i}) ~= height(meter{i})
            class(i,1) = meter{i}.serving_revised(1);
            class(i,2) = meter{i}.Serving(1);
            class(i,3) = {'B'};
            meter3{i} = [];
        end
    end
end


% A class

for i = 1:length(meter3)
    if isempty(meter3{i}) ~= 1
        class(i,1) = meter3{i}.serving_revised(1);
        class(i,2) = meter3{i}.Serving(1);
        class(i,3) = {'A'};
    end
end
        


%% Update Checklist

Month = month(SyneticaData.timestamp(1),'shortname');
Month = string(Month);


Year = year(SyneticaData.timestamp(1));
Year = string(Year);


DataMonth = append(Month,Year);


buildingChecklist = readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica Checklist.xlsx');
BuildingChecklist = buildingChecklist;


VarNames = string(BuildingChecklist.Properties.VariableNames);

num = find(VarNames == DataMonth);

theor_numofmeters = height(BuildingChecklist);

quality = zeros(theor_numofmeters,1);
quality = string(quality);
quantity = zeros(theor_numofmeters,1);

for i = 1:theor_numofmeters
    for j = 1:1:length(data_percent)
        if BuildingChecklist.name(i) == data_percent(j,1)
            quantity(i,1)= data_percent(j,2);
            quality(i,1) = string(class(j,3));
            %BuildingChecklist{i,num}(2) = string(class(j,3));
        end
    end
end

if ismember(DataMonth,VarNames) == 0
    BuildingChecklist.(DataMonth) = [quantity quality];
end


% Insert File Address Here
writetable(BuildingChecklist, 'C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica Checklist.xlsx');

       

%% Classify 

if classIfy == "yes"

% create list of building names and "Serving" 
for i = 1:length(meter2)
    building_names(i,1) = string(meter2{i}.serving_revised(1));
    meter_description(i,1) = meter2{i}.Serving(1);
end

% ensure cells are arranged in correct way

for i= 1:length(avg_weekday_norm)
avg_weekday_norm{i} = avg_weekday_norm{i}';
end


    numClasses = 4;

    load('elec_class_net.mat')
    
    miniBatchSize = 48;
    
    YPred = classify(elec_class_net,avg_weekday_norm, ...
        'MiniBatchSize',miniBatchSize, ...
        'SequenceLength','longest');
    

YPred = double(YPred);


% creates table to compare classification of meters 
classify_verify = table(YPred,building_names,meter_description, avg_weekday_norm, avg_weekday);

% splits each meter into its classification
 for n = 1:numClasses
     for j = 1:height(classify_verify)
         if classify_verify.YPred(j) == n
             type_classify{1,n}(j,:) = classify_verify(j,:);  
         end
     end   
 end
 
  for n = 1:numClasses
      type_classify{1,n} = type_classify{1,n}(type_classify{1,n}.YPred ~= 0,:);
  end

 % plots all of the meters of each class 

 for j = 1:numClasses
     
     figure(18)
     for f = 1:height(type_classify{1,j})
         subplot(4,1,j)
         plot(time,cell2mat(type_classify{1,j}.avg_weekday_norm(f)))
         hold on
     end
     %legend([type{1,j}.building_names_train])
     title(['type' '-' type_classify{j}.YPred(1) '-' 'building'])
     %sgtitle([Metertype '-' DataMonth])
 end

% plots average profile for each class

letters = string({'a','b','c','d','e'});

 for j = 2:numClasses
     avg_profile(:,j) = mean(cell2mat(type_classify{j}.avg_weekday_norm));
     figure(13)
     subplot(3,1,j-1)
     plot(time,avg_profile(:,j))
     hold on
     %legend([type{1,j}.building_names_train])
     title([letters(j-1)])
     %sgtitle([Metertype '-' DataMonth])
 end


for n = 1:numClasses
    build_type_total(n) = trapz(cell2mat(type_classify{n}.avg_weekday(1)));
    for i = 2:height(type_classify{n})
        build_type_total(n) = build_type_total(n) + trapz(cell2mat(type_classify{n}.avg_weekday(i)));
    end
end

% plots pie chart to describe split of energy comsumption between meters 
figure()
pie(build_type_total)
% legend()
title('Pie Chart Showing the Distribution of Electrical Consumption across Building Types Across Campus')


                
end
    
    
    