function out = run_cabin_load_analysis(cfg)
%RUN_CABIN_LOAD_ANALYSIS Reproduce the recovered Excel sensible-load subtotal.

out.inputs = read_project_csv(cfg.files.cabinLoadInputs, ...
    {'LoadComponent','Load_kW','CabinSetpoint_C', ...
     'InteriorRelativeHumidity_pct','SourceWorkbook','SourceStatus'}, ...
    {'Load_kW','CabinSetpoint_C','InteriorRelativeHumidity_pct'});
out.summary = calculate_cabin_partial_load(out.inputs);
writetable(out.summary,fullfile(cfg.project.outputDir,'cabin_partial_load_result.csv'));
end
