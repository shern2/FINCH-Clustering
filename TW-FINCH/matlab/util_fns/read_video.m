function [vid_feats, gt_label_frame, vid_name]= read_video(files, datasets_path, video, Dataset)

gt_path=fullfile(datasets_path, Dataset, 'groundTruth'); 
mapping_path = fullfile(datasets_path, Dataset, 'mapping');

buf = textscan(files{video},'%s','Delimiter','/');
buf=buf{1}; 
vid_name = buf{end}; vid_name=vid_name(1:end-4);
if strcmp(Dataset, 'MPII_Cooking')
    vid_feats = readtable(files{video});
    vid_feats=table2array(vid_feats(:, 1:end-1));
elseif strcmp(Dataset, 'Hollywood_extended')
    vid_feats = readtable(files{video});
    vid_feats=table2array(vid_feats(:, 2:end-1));
    vid_name = buf{end};
else
    vid_feats=table2array(readtable(files{video}));
end


if strcmp(Dataset, 'YTI')
    gt_label_frame=table2array(readtable(fullfile(gt_path, vid_name), 'Delimiter', '#', 'ReadVariableNames',false));
    
elseif strcmp(Dataset, 'Breakfast')|strcmp(Dataset, '50Salads')
    map=readtable(fullfile(mapping_path, 'mapping.txt'));
    map2=table([1:numel(map.Var2)]', 'RowNames', map.Var2);
    gt_label_str=table2cell(readtable(fullfile(gt_path, vid_name), 'Delimiter', '#', 'ReadVariableNames',false));
    gt_label_frame=table2array(map2(gt_label_str,1));
    
else
    gt_label_frame=table2cell(readtable(fullfile(gt_path, vid_name), 'Delimiter', '#', 'ReadVariableNames',false));
    gt_label_frame=grp2idx(gt_label_frame);
end


 
% for YTI .. map label -1 to 1..  for computing iou label -1 doesnt work in matlab
min_val = min(gt_label_frame);
if min_val < 0 
    add_fac =  abs(min_val) + 1;
    gt_label_frame = gt_label_frame + add_fac;
end

%% Youtube wo_bg 75
if strcmp(Dataset, 'YTI')
    tau=[0.75];
    bg_index=find(gt_label_frame==1);
    T = floor(tau * length(bg_index));
    wo_bg=T;
    ind_wo_bg = randperm(length(bg_index), wo_bg); 
    drop_indexes_wo_bg = bg_index(ind_wo_bg);

    vid_feats(drop_indexes_wo_bg, :) =[];
    gt_label_frame(drop_indexes_wo_bg) =[];
end


%% handle empty feats-- some feature vectors are all zeros.. put a small constant there to avoid nans
rem_idx=find(all(vid_feats==0, 2));
vid_feats(rem_idx,:)=(vid_feats(rem_idx,:)+1)*1e-4;



if strcmp(Dataset, 'Hollywood_extended')
    % check labels as they are not always aligned to provided features
    num_feats = size(vid_feats, 1);
    num_labels = size(gt_label_frame, 1);
    diff=abs(num_feats - num_labels);
    if num_labels~=num_feats
        if num_feats > num_labels
            gt_label_frame=[ones(diff, 1);gt_label_frame];
        else
            vid_feats=[vid_feats(1:diff,:);vid_feats];
        end
    end
end


end