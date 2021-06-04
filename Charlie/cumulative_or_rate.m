%% Synetica Classify Cumulative or Rate Training

% Script to train a model and test to classify if its cumulative or rate. 

%% Import the Data and Change Strings to Categories

clear all

SyneticaData = []; % INSERT TRAINING DATA FILE E.G readtable('C:\Users\charl\AppData\Local\Temp\synetica-feb-2019.csv'); %imports synetica file chosen by user

SyneticaData.name = categorical(SyneticaData.name);
SyneticaData.units = categorical(SyneticaData.units);
SyneticaData.device_id = categorical(SyneticaData.device_id);
Syneticameterlist = readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica_meter_list_210122.xlsx');
Syneticameterlist.MeterID= categorical(Syneticameterlist.MeterID);
Syneticameterlist.Properties.VariableNames{1} = 'name';
Syneticameterlist.MeterType = categorical(Syneticameterlist.MeterType);
Syneticameterlist.serving_revised = categorical(Syneticameterlist.serving_revised);
Syneticameterlist.class = categorical(Syneticameterlist.class);
Syneticameterlist.units_after_conversion = categorical(Syneticameterlist.units_after_conversion);

SyneticaData_test = []; % INSERT TEST DATA FILE E.G readtable('C:\Users\charl\AppData\Local\Temp\synetica-apr-2018.csv'); %imports synetica file chosen by user

SyneticaData_test.name = categorical(SyneticaData_test.name);
SyneticaData_test.units = categorical(SyneticaData_test.units);
SyneticaData_test.device_id = categorical(SyneticaData_test.device_id);

%% Filter and Join the Datasets

% use innerjoin the combine the appropriatley filtered meter list with the syentica data for the chosen month 
joinedData = innerjoin(Syneticameterlist,SyneticaData,'Keys',...
    {'name'});
joinedData_test = innerjoin(Syneticameterlist,SyneticaData_test,'Keys',...
    {'name'});


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

% creates a cell that contains all of the information for each cell 
for i = 1:numberofmeters
    for j = 1:Width
        meter_training{1,i}(:,j) = table(meters{i,j});
    end
end  

for i = 1:numberofmeters_test
    for j = 1:Width_test
        meter_testing{1,i}(:,j) = table(meters_test{i,j});
    end
end  

 %could do a massive loop and for number of buildings and it filters the
 %data for each building first, how would i get that on indiviudal excel
 %docs?

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
    for j = 1:width(meter_training{1,i})
        if class(table2array(meter_training{1,i}(1,j))) ~= "double"
            if table2array(meter_training{1,i}(1,j)) == "" 
                meter_training{1,i}(:,j) = {'empty'};
            elseif ismissing(table2array(meter_training{1,i}(1,j))) == 1 
                meter_training{1,i}(:,j) = {'empty'};
            end
        
        end
    end
end

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
    for j = 1:width(meter_testing{1,i})
        if class(table2array(meter_testing{1,i}(1,j))) ~= "double"
            if table2array(meter_testing{1,i}(1,j)) == "" 
                meter_testing{1,i}(:,j) = {'empty'};
            elseif ismissing(table2array(meter_testing{1,i}(1,j))) == 1 
                meter_testing{1,i}(:,j) = {'empty'};
            end
        
        end
    end
end



% % pick out meters that have at least data OF class A
% buildingChecklist = readtable('C:\Users\charl\OneDrive\Documents\Fourth Year Project\Data\Synetica Checklist.xlsx');
% 
% Month = month(SyneticaData.timestamp(1),'shortname');
% Month = string(Month);
% 
% Year = year(SyneticaData.timestamp(1));
% Year = string(Year);
% 
% DataMonth = append(Month,Year,'_2');
% 
% VarNames = string(buildingChecklist.Properties.VariableNames);
% 
% column = find(VarNames == DataMonth); 
% 
% for i = 1:numberofmeters
%     row = find(buildingChecklist.name == meter_training{1,i}.name(1));
%     if table2array(buildingChecklist(row,column)) ~= "A"
%         meter_training{1,i} = [];
%     end
% end
% 
% meter_training = meter_training(~cellfun('isempty',meter_training));
% 
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


 for i = 1:length(training_data)

smooth_normal_train{1,i} = normalize(movavg(meter_train{1,i}.reading,'simple',20),'range');

 end
 
  for i = 1:length(test_data)

smooth_normal_test{1,i} = normalize(movavg(meter_test{1,i}.reading,'simple',20),'range');

 end
 
 
%% Stats Table


for i = 1:length(meter_train)
    building_names_train(i,1) = string(meter_train{i}.serving_revised(1));
    meter_description_train(i,1) = meter_train{i}.Serving(1);
    units_train(i,1) = string(meter_train{i}.units_after_conversion(1));
end

% for i = 1:length(avg_weekday_train)
%     figure(i)
% plot(time', avg_weekday_train{i})
% title([building_names_train(i) '-' meter_description_train(i)])
% end


for i = 1:length(meter_test)
    building_names_test(i,1) = string(meter_test{i}.serving_revised(1));
    meter_description_test(i,1) = meter_test{i}.Serving(1);
    units_test(i,1) = string(meter_test{i}.units_after_conversion(1));
end

clear building_types_train

for i = 1:length(meter_train)
    class_train(i,1) = categorical(meter_train{1,i}.class(1));
end

for i = 1:length(meter_test)
    class_test(i,1) = categorical(meter_test{1,i}.class(1));
end

class_train = table(class_train);

class_test = table(class_test);

Stats_train = table(building_names_train,meter_description_train);

for i = 1:length(smooth_normal_train)
    
    st_dev = std(smooth_normal_train{i});
    Min = min(smooth_normal_train{i});
    Max = max(smooth_normal_train{i});
    Var = var(smooth_normal_train{i});
    Mean = mean(smooth_normal_train{i});
    Median = median(smooth_normal_train{i});
    
    Stats_train.st_dev(i) = st_dev;
    Stats_train.Min(i) = Min;
    Stats_train.Max(i) = Max;
    Stats_train.Var(i) = Var;
    Stats_train.Mean(i) = Mean;
    Stats_train.Median(i) = Median;

end

Stats_train = [Stats_train class_train];

Stats_test = table(building_names_test,meter_description_test);

for i = 1:length(smooth_normal_test)
    
    st_dev = std(smooth_normal_test{i});
    Min = min(smooth_normal_test{i});
    Max = max(smooth_normal_test{i});
    Var = var(smooth_normal_test{i});
    Mean = mean(smooth_normal_test{i});
    Median = median(smooth_normal_test{i});
    
    Stats_test.st_dev(i) = st_dev;
    Stats_test.Min(i) = Min;
    Stats_test.Max(i) = Max;
    Stats_test.Var(i) = Var;
    Stats_test.Mean(i) = Mean;
    Stats_test.Median(i) = Median;

end

Stats_test = [Stats_test class_test];

%% Classify train

inputTable = Stats_train(:,3:end);
predictorNames = {'st_dev', 'Min', 'Max', 'Var', 'Mean', 'Median'};
predictors = inputTable(:, predictorNames);
response = inputTable.class_train;
isCategoricalPredictor = [false, false, false, false, false, false];

% Train a classifier
% This code specifies all the classifier options and trains the classifier.
classificationKNN = fitcknn(...
    predictors, ...
    response, ...
    'Distance', 'Euclidean', ...
    'Exponent', [], ...
    'NumNeighbors', 10, ...
    'DistanceWeight', 'SquaredInverse', ...
    'Standardize', true, ...
    'ClassNames', categorical({'Cumulative'; 'Rate'}, {'Cumulative' 'Rate' 'TBC'}));

% Create the result struct with predict function
predictorExtractionFcn = @(t) t(:, predictorNames);
knnPredictFcn = @(x) predict(classificationKNN, x);
trainedClassifier.predictFcn = @(x) knnPredictFcn(predictorExtractionFcn(x));

% Add additional fields to the result struct
trainedClassifier.RequiredVariables = {'Max', 'Mean', 'Median', 'Min', 'Var', 'st_dev'};
trainedClassifier.ClassificationKNN = classificationKNN;
trainedClassifier.About = 'This struct is a trained model exported from Classification Learner R2020a.';
trainedClassifier.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedModel''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appclassification_exportmodeltoworkspace'')">How to predict using an exported model</a>.');

% Extract predictors and response
% This code processes the data into the right shape for training the
% model.
inputTable = Stats_train(:,3:end);
predictorNames = {'st_dev', 'Min', 'Max', 'Var', 'Mean', 'Median'};
predictors = inputTable(:, predictorNames);
response = inputTable.class_train;
isCategoricalPredictor = [false, false, false, false, false, false];

% Perform cross-validation
partitionedModel = crossval(trainedClassifier.ClassificationKNN, 'KFold', 5);

% Compute validation predictions
[validationPredictions, validationScores] = kfoldPredict(partitionedModel);

% Compute validation accuracy
validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');

% verfiy

yfit = trainedClassifier.predictFcn(Stats_test(:,3:end));

acc = sum(string(yfit) == string(table2array(class_test)))./numel(class_test)

