function metricsToPhy(rez, savePath, cid, uQ, isiV, cR, histC)
    if ~isempty(savePath)
        fileID = fopen(fullfile(savePath, 'cluster_Quality.tsv'),'w');
        fprintf(fileID, 'cluster_id%sQuality', char(9));
        fprintf(fileID, char([13 10]));

        fileIDCP = fopen(fullfile(savePath, 'cluster_ISIv.tsv'),'w');
        fprintf(fileIDCP, 'cluster_id%sISIv', char(9));
        fprintf(fileIDCP, char([13 10]));

        fileIDA = fopen(fullfile(savePath, 'cluster_contamRt.tsv'),'w');
        fprintf(fileIDA, 'cluster_id%scontamRt', char(9));
        fprintf(fileIDA, char([13 10]));
        
        fileIDH = fopen(fullfile(savePath, 'cluster_histC.tsv'),'w');
        fprintf(fileIDH, 'cluster_id%shistC', char(9));
        fprintf(fileIDH, char([13 10]));        

        %rez.est_contam_rate(isnan(rez.est_contam_rate)) = 1;
        for j = 1:length(cid)
            
            fprintf(fileID, '%d%s%.1f', cid(j) - 1, char(9), uQ(j));
            fprintf(fileID, char([13 10]));

            fprintf(fileIDCP, '%d%s%.1f', cid(j) - 1, char(9), isiV(j));
            fprintf(fileIDCP, char([13 10]));

            fprintf(fileIDA, '%d%s%.2f',cid(j) - 1, char(9), cR(j));
            fprintf(fileIDA, char([13 10]));
            
            fprintf(fileIDH, '%d%s%.2f',cid(j) - 1, char(9), histC(j));
            fprintf(fileIDH, char([13 10]));            

        end
        fclose(fileID);
        fclose(fileIDCP);
        fclose(fileIDA);
        fclose(fileIDH);
    end