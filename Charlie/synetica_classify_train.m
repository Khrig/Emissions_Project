%% Synetica Electrical Cluster/Classify Train



%% Import the Data and Change Strings to Categories

clear all

Metertype = 'Electricity';

SyneticaData = []; % INSERT RAW DATA FILE 1 FOR TRAIN E.G readtable('C:\Users\charl\AppData\Local\Temp\synetica-feb-2020.csv'); %imports synetica file chosen by user
SyneticaData.name = categorical(SyneticaData.name);
%SyneticaData.units = categorical(SyneticaData.units);
SyneticaData.device_id = categorical(SyneticaData.device_id);
Syneticameterlist = []; %INSERT METADATA FILEreadtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica_meter_list_210122.xlsx');
Syneticameterlist.name = categorical(Syneticameterlist.name);
Syneticameterlist.MeterType = categorical(Syneticameterlist.MeterType);
Syneticameterlist.serving_revised = categorical(Syneticameterlist.serving_revised);
Syneticameterlist.class = categorical(Syneticameterlist.class);
Syneticameterlist.units_after_conversion = string(Syneticameterlist.units_after_conversion);

SyneticaData_test = []; % INSERT RAW DATA FILE 1 FOR TRAIN E.G readtable('C:\Users\charl\AppData\Local\Temp\synetica-may-2018.csv'); %imports synetica file chosen by user
SyneticaData_test.name = categorical(SyneticaData_test.name);
SyneticaData_test.units = string(SyneticaData_test.units);
SyneticaData_test.device_id = categorical(SyneticaData_test.device_id);

%% Filter and Join the Datasets

% filter the meter list for only values from heat meters
Syneticameterlist = Syneticameterlist(Syneticameterlist.MeterType == Metertype,:);

% just for power 
Syneticameterlist = Syneticameterlist(ismember(Syneticameterlist.units_after_conversion,{'kWh','MWh','KW','MW'}),:);

% filter the meter list for values that only of type 'Rate'

% Syneticameterlist = Syneticameterlist(ismember(Syneticameterlist.class,{'Rate'}),:);

% use innerjoin the combine the appropriatley filtered meter list with the syentica data for the chosen month 
joinedData = innerjoin(Syneticameterlist,SyneticaData,'Keys',...
    {'name'});
joinedData_test = innerjoin(Syneticameterlist,SyneticaData_test,'Keys',...
    {'name'});

joinedData = joinedData(~ismember(joinedData.serving_revised,{'Energy Centre'}),:);
joinedData_test = joinedData_test(~ismember(joinedData_test.serving_revised,{'Energy Centre'}),:);

%% Split and Plot the Data (based on 'name'/MeterID)


% finds the new number of meters in the data 
G = findgroups(joinedData.name);  
numberofmeters = max(G);
G_test = findgroups(joinedData_test.name);  
numberofmeters_test = max(G_test);

% creates a cell that contains the indidual columns of data for each meter
meters = splitapply( @(varargin) varargin, joinedData, G);
meters_test = splitapply( @(varargin) varargin, joinedData_test, G_test);

% calculates the number of columns in the data 
Width = width(joinedData);
Width_test = width(joinedData_test);

% creates a cell that contains all of the information for each cell for
% training (creates a training set)
for i = 1:numberofmeters
    for j = 1:Width
        meter_training{1,i}(:,j) = table(meters{i,j});
    end
end  

% repeats for testing

for i = 1:numberofmeters_test
    for j = 1:Width_test
        meter_testing{1,i}(:,j) = table(meters_test{i,j});
    end
end  


% assigns the appropraiet variable names to all of the meter tables

for i = 1:numberofmeters
    meter_training{1, i}.Properties.VariableNames{1} = 'name';
    meter_training{1, i}.Properties.VariableNames{2} = 'MeterType';
    meter_training{1, i}.Properties.VariableNames{3} = 'Serving';
    meter_training{1, i}.Properties.VariableNames{4} = 'serving_revised';
    meter_training{1, i}.Properties.VariableNames{5} = 'class';
    meter_training{1, i}.Properties.VariableNames{6} = 'units_after_conversion';
    meter_training{1, i}.Properties.VariableNames{7} = 'timestamp';
    meter_training{1, i}.Properties.VariableNames{8} = 'device_id';
    meter_training{1, i}.Properties.VariableNames{9} = 'reading';
    meter_training{1, i}.Properties.VariableNames{10} = 'units';
    meter_training{1, i}.units_after_conversion = string(meter_training{1, i}.units_after_conversion);
    for j = 1:width(meter_training{1,i})
        if class(table2array(meter_training{1,i}(1,j))) ~= "double"
            if table2array(meter_training{1,i}(1,j)) == ""
                meter_training{1,i}(:,j) = {'empty'};
            end
        end
    end
end



% repeat for testing

for i = 1:numberofmeters_test
    meter_testing{1, i}.Properties.VariableNames{1} = 'name';
    meter_testing{1, i}.Properties.VariableNames{2} = 'MeterType';
    meter_testing{1, i}.Properties.VariableNames{3} = 'Serving';
    meter_testing{1, i}.Properties.VariableNames{4} = 'serving_revised';
    meter_testing{1, i}.Properties.VariableNames{5} = 'class';
    meter_testing{1, i}.Properties.VariableNames{6} = 'units_after_conversion';
    meter_testing{1, i}.Properties.VariableNames{7} = 'timestamp';
    meter_testing{1, i}.Properties.VariableNames{8} = 'device_id';
    meter_testing{1, i}.Properties.VariableNames{9} = 'reading';
    meter_testing{1, i}.Properties.VariableNames{10} = 'units';
    meter_testing{1, i}.units_after_conversion = string(meter_testing{1, i}.units_after_conversion);
    for j = 1:width(meter_testing{1,i})
        if class(table2array(meter_testing{1,i}(1,j))) ~= "double"
            if table2array(meter_testing{1,i}(1,j)) == ""  
                meter_testing{1,i}(:,j) = {'empty'};
            end
        end
    end
end

% pick out meters that have at least 80% of data
buildingChecklist = [];% INSERT BUILDING CHECKLIST FORM FILE readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica Checklist.xlsx');

Month = month(SyneticaData.timestamp(1),'shortname');
Month = string(Month);

Year = year(SyneticaData.timestamp(1));
Year = string(Year);

DataMonth = append(Month,Year);

VarNames = string(buildingChecklist.Properties.VariableNames);

column = find(VarNames == DataMonth); 

for i = 1:numberofmeters
    row = find(buildingChecklist.name == meter_training{1,i}.name(1));
    if table2array(buildingChecklist(row,column)) < 60
        meter_training{1,i} = [];
    end
end

meter_training = meter_training(~cellfun('isempty',meter_training));

%% convert from cum to rate

for i = 1:length(meter_training)
    if meter_training{1,i}.class(1) == "Cumulative"
        meter_training{1,i}.reading(1:end-1) = diff(meter_training{1,i}.reading);
        meter_training{1,i}.reading(end) = meter_training{1,i}.reading(end-1);
         for j = 1:height(meter_training{1,i})
              if meter_training{1,i}.reading(j) < 0 
              meter_training{1,i}.reading(j) = 0;
              end
         end
        meter_training{1,i}.reading = filloutliers(meter_training{1,i}.reading,'previous', 'movmedian', 9);
    end
end

for i = 1:length(meter_testing)
    if meter_testing{1,i}.class(1) == "Cumulative"
        meter_testing{1,i}.reading(1:end-1) = diff(meter_testing{1,i}.reading);
        meter_testing{1,i}.reading(end) = meter_testing{1,i}.reading(end-1);
         for j = 1:height(meter_testing{1,i})
              if meter_testing{1,i}.reading(j) < 0 
              meter_testing{1,i}.reading(j) = 0;
              end
         end
        meter_testing{1,i}.reading = filloutliers(meter_testing{1,i}.reading,'previous', 'movmedian', 9);
    end
end




training_data = meter_training;

test_data = meter_testing;


%% Average Daily Profile for each meter for this particular month

% fill out any missing parts to data

for i = 1:length(training_data)
TT_Train{1,i} = table2timetable(training_data{1,i});
TT_Train{1,i} = sortrows(TT_Train{1, i},'timestamp','ascend');
TT_Train{1,i} = unique(TT_Train{1,i});
TT_Train{1,i} = rmmissing(TT_Train{1,i});
TT_Train{1,i} = retime(TT_Train{1,i},'regular', 'previous','TimeStep',minutes(10));
end

for i = 1:length(test_data)
TT_Test{1,i} = table2timetable(test_data{1,i});
TT_Test{1,i} = sortrows(TT_Test{1, i},'timestamp','ascend');
TT_Test{1,i} = unique(TT_Test{1,i});
TT_Test{1,i} = rmmissing(TT_Test{1,i});
TT_Test{1,i} = retime(TT_Test{1,i},'regular', 'previous','TimeStep',minutes(10));
end

% converts the timetable back to a table
for i = 1:length(training_data)
meter_train{1,i} = timetable2table(TT_Train{1,i});
end

for i = 1:length(test_data)
meter_test{1,i} = timetable2table(TT_Test{1,i});
end


% fills out missing data points, configures average daily profile for a
% weekday and for weekend that is normalised and smoothed out 

 for i = 1:length(training_data)
      DayNumber = weekday(meter_train{1,i}.timestamp); 
 timeofDay = timeofday(meter_train{1,i}.timestamp);
 WeekEnd = isweekend(meter_train{1,i}.timestamp);
 
 meter_train{1,i}.Weekend = WeekEnd;
 meter_train{1,i}.Timeofday = timeofDay;
 
 % finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
 groups = findgroups(meter_train{1,i}.Weekend, meter_train{1,i}.Timeofday);
 
 % adds the groups as a variable to each table in the cell
 meter_train{1,i}.group = groups;
 l = height(meter_train{1,i});
 
 % constructs a time variable for plotting purposes
 time1 = datetime(2018,1,1,0,0,0);
 time2 = datetime(2018,1,1,23,50,0);
 time = time1:minutes(10):time2;
 


 Weekday_train = groupsummary(meter_train{1,i},{'group'},'mean','reading','IncludeMissingGroups',false);
 Weekday_train.Properties.VariableNames{3} = 'Average_Reading';
    
 
% creates normalised and non normalised average weekday and weekend profile  
 
avg_weekday_train{i,1} = normalize(movavg(Weekday_train.Average_Reading(1:144),'simple',20),'range');
avg_weekday_train2{i,1} = movavg(Weekday_train.Average_Reading(1:144),'simple',20);

avg_weekend_train{i,1} = normalize(movavg(Weekday_train.Average_Reading(145:end),'simple',20),'range');
avg_weekend_train2{i,1} = movavg(Weekday_train.Average_Reading(145:end),'simple',20);

 end
 
 
% repeats for test

 for i = 1:length(meter_test)
      DayNumber = weekday(meter_test{1,i}.timestamp); 
 timeofDay = timeofday(meter_test{1,i}.timestamp);
 WeekEnd = isweekend(meter_test{1,i}.timestamp);
 
 meter_test{1,i}.Weekend = WeekEnd;
 meter_test{1,i}.Timeofday = timeofDay;
 
 % finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
 groups = findgroups(meter_test{1,i}.Weekend, meter_test{1,i}.Timeofday);
 
 % adds the groups as a variable to each table in the cell
 meter_test{1,i}.group = groups;
 l = height(meter_test{1,i});
 

 Weekday_test = groupsummary(meter_test{1,i},{'group'},'mean','reading','IncludeMissingGroups',false);
 Weekday_test.Properties.VariableNames{3} = 'Average_Reading';

  
% creates normalised and non normalised average weekday and weekend profile  
 
avg_weekday_test{i,1} = normalize(movavg(Weekday_test.Average_Reading(1:144),'simple',20),'range');
avg_weekday_test2{i,1} = movavg(Weekday_test.Average_Reading(1:144),'simple',20);

avg_weekend_test{i,1} = normalize(movavg(Weekday_test.Average_Reading(145:end),'simple',20),'range');
avg_weekend_test2{i,1} = movavg(Weekday_test.Average_Reading(145:end),'simple',20);


 end
%% Clustering prep

clear building_names_train
clear meter_description_train
clear units
clear Heirarchical
clear type
clear cluster_energy_weekday_train
clear cluster_verify2

% creates a pre-defined sized array for training and testing data to
% convert from table format

cluster_energy_weekday_train = zeros(length(avg_weekday_train),144);
cluster_energy_weekday_test = zeros(length(avg_weekday_test),144);


for i = 1:length(meter_train)
    building_names_train(i,1) = string(meter_train{i}.serving_revised(1));
    meter_description_train(i,1) = meter_train{i}.Serving(1);
    units_train(i,1) = string(meter_train{i}.units(1));
end

% UNCOMMENT if you want to verify and observe the average daily profiles
% for i = 1:length(avg_weekday_train)
%     figure(i)
% plot(time', avg_weekday_train{i})
% title([building_names_train(i) '-' meter_description_train(i)])
% end


for i = 1:length(meter_test)
    building_names_test(i,1) = string(meter_test{i}.serving_revised(1));
    meter_description_test(i,1) = meter_test{i}.Serving(1);
    units_test(i,1) = string(meter_test{i}.units(1));
end

% Clustering train

% uncommet if not using dtw distance 
distance_method = ["euclidean" "squaredeuclidean" "seuclidean" "mahalanobis" "cityblock" "minkowski" "chebychev" "cosine" "correlation" "hamming" "jaccard" "spearman"];
linkage_method = ["average" "centroid" "complete" "median" "single" "ward" "weighted"];


for i = 1:length(training_data)
    x = length(avg_weekday_train{i});  %should be 144
    cluster_energy_weekday_train(i,1:x) = avg_weekend_train{i};
end

i = 1;
j = 6;
numclusters = 4;
%distance_method(i)

Y = pdist(cluster_energy_weekday_train,distance_method(i));
Z = linkage(Y, linkage_method(j));
figure(i*10)
dendrogram(Z)
title([distance_method(i) '-' linkage_method(j)])
I = inconsistent(Z);
Heirarchical = cluster(Z,'maxclust',numclusters);


numberofmeters = length(meter_train);

% building_names_train = building_names_train';
% meter_description_train= meter_description_train';
% units_train = units_train';

% creates a table to understand how the buildings have been clustered
cluster_verify2_train = table(Heirarchical, building_names_train,meter_description_train, avg_weekday_train); %string(building_types_train));


% seperates the clusters and plots the buildings in the cluster specified 
 for n = 1:max(Heirarchical)
     for j = 1:height(cluster_verify2_train)
         if cluster_verify2_train.Heirarchical(j) == n
             type{1,n}(j,:) = cluster_verify2_train(j,:);  
         end
     end   
 end


 
 
 
  for n = 1:max(Heirarchical)
      type{1,n} = type{1,n}(type{1,n}.Heirarchical ~= 0,:);
  end
  
 
 
 for j = 1:numclusters
     figure(101)
     for f = 1:height(type{1,j})
         subplot(round(numclusters/2),2,j)
         plot(time,cell2mat(type{1,j}.avg_weekday_train(f)))
         hold on
     end
     %legend([type{1,j}.building_names_train])
     title(['type' '-' num2str(j) '-' 'building'])
     %sgtitle([Metertype '-' DataMonth])
 end
 
 % for plotting individual group
%  for j = 8
%      figure(13)
%      for f = 1:height(type{1,j})
%          plot(time,cell2mat(type{1,j}.avg_weekday_train(f)))
%          hold on
%      end
%      legend([type{1,j}.building_names_train])
%      title(['type' '-' num2str(j) '-' 'building'])
%      %sgtitle([Metertype '-' DataMonth])
%  end

%%
Heirarchical_orig = Heirarchical;
%Heirarchical = Heirarchical_orig;


% creates classes for clusters 
 for i = 1:length(Heirarchical)
     if Heirarchical(i) == 4
         Building_Type(i,1) = "Working Day";
     elseif Heirarchical(i) == 3 
         Building_Type(i,1) = "Recreational";
     elseif Heirarchical(i) == 1
         Building_Type(i,1) = "Residential";
     else
         Building_Type(i,1) = "Other";
     end
 end



 %% LSTM 
% 
% ensure cells are arranged in correct way
% 
for i= 1:length(avg_weekday_train)
avg_weekday_train{i} = avg_weekday_train{i}';
end


for i= 1:length(avg_weekday_test)
avg_weekday_test{i} = avg_weekday_test{i}';
end

inputSize = 1;
numHiddenUnits = 100;
numClasses = 4;

layers = [ ...
    sequenceInputLayer(inputSize)
    bilstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];


% 'ValidationData',{avg_weekday_test,building_types_test}, ...

miniBatchSize = 48;
options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'MaxEpochs',100, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'Shuffle','every-epoch', ...
    'Verbose',false, ...
    'Plots','training-progress');

Building_Type = categorical(Building_Type);

elec_class_net = trainNetwork(avg_weekday_train,Building_Type,layers,options);

save('elec_class_net.mat', 'elec_class_net');


YPred = classify(elec_class_net,avg_weekday_test, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');


YPred = double(YPred);


% CAN I VERIFY?
classify_verify = table(YPred,building_names_test,meter_description_test, avg_weekday_test, avg_weekday_test2);


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

 

 for j = 1:numClasses
     figure(16)
     for f = 1:height(type_classify{1,j})
         subplot(round(numClasses/2),2,j)
         plot(time,cell2mat(type_classify{1,j}.avg_weekday_test(f)))
         hold on
     end
     %legend([type{1,j}.building_names_train])
     title(['type' '-' num2str(j) '-' 'building'])
     %sgtitle([Metertype '-' DataMonth])
 end




 %% Dynamic Time Warping (DTW) Function

 function dist = dtwf(x,y)
% n = numel(x);
m2 = size(y,1);
dist = zeros(m2,1);
for i=1:m2
    dist(i) = dtw(x,y(i,:));
end
end
