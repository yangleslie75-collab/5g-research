function run_4class_encrypted(baseSeed)
if nargin < 1
    baseSeed = 2026;
end

clc; close all;
rng(baseSeed);

cfg.samplesPerClass = 1800;
cfg.snrRangeDb = [-5 20];
cfg.snrSummaryBins = [-5 0 5 10 15 20];

cfg.fftCandidates = [128 256 512];
cfg.cpCandidates  = [16 32 64];
cfg.modCandidates = {'QPSK','16QAM','64QAM'};

cfg.sampleRate = 30.72e6;
cfg.ul.scsKHz = 30;
cfg.ul.slotDurationMs = 0.5;
cfg.ul.subframeMs = 1.0;
cfg.ul.modSet = {'QPSK','16QAM','64QAM'};
cfg.ul.mcsSet = [4 8 12 16 20 24];
cfg.ul.numOFDMSymbolsRange = [7 14];
cfg.ul.prbRange = [12 106];
cfg.ul.activeScRatioMax = 0.85;
cfg.ul.dmrsOverheadRatio = 0.08;
cfg.ul.addMacLengthHeader = false;
cfg.ul.enableBitScrambling = true;
cfg.ul.rnti = 4660;
cfg.ul.cellId = 42;

cfg.guardZeros = 300;

cfg.nrPhy.enable = true;
cfg.nrPhy.require5GToolbox = true;
cfg.nrPhy.nSizeGrid = 52;
cfg.nrPhy.subcarrierSpacing = 30;
cfg.nrPhy.cyclicPrefix = 'normal';
cfg.nrPhy.nCellID = cfg.ul.cellId;
cfg.nrPhy.rnti = cfg.ul.rnti;
cfg.nrPhy.nStartGrid = 0;
cfg.nrPhy.nStartBWP = 0;
cfg.nrPhy.numLayers = 1;
cfg.nrPhy.symbolAllocation = [0 14];
cfg.nrPhy.mappingType = 'A';
cfg.nrPhy.transformPrecoding = false;
cfg.nrPhy.dmrsConfigurationType = 1;
cfg.nrPhy.dmrsTypeAPosition = 2;
cfg.nrPhy.dmrsLength = 1;
cfg.nrPhy.dmrsAdditionalPosition = 1;
cfg.nrPhy.delayProfile = 'TDL-C';
cfg.nrPhy.delaySpread = 100e-9;
cfg.nrPhy.maximumDopplerShift = 5;
cfg.nrPhy.numTransmitAntennas = 1;
cfg.nrPhy.numReceiveAntennas = 1;
cfg.nrPhy.rxGainDb = 0;
cfg.nrPhy.applyLegacyRfImpairments = true;
cfg.nrPhy.addBackgroundInterference = true;
cfg.nrPhy.frontendFftCandidates = [512 1024 2048];
cfg.nrPhy.frontendCpCandidates = [36 72 144];

if cfg.nrPhy.enable
    cfg.fftCandidates = cfg.nrPhy.frontendFftCandidates;
    cfg.cpCandidates = cfg.nrPhy.frontendCpCandidates;
end

cfg.rrcLike.enable = true;
cfg.rrcLike.state = 'RRC_CONNECTED';
cfg.rrcLike.srbId = 1;
cfg.rrcLike.drbId = 1;
cfg.rrcLike.pduSessionId = 1;
cfg.rrcLike.qfi = 9;
cfg.rrcLike.securityMode = 'SecurityModeComplete-like';
cfg.rrcLike.measurementConfig = 'CSI/RSRP logging only';

cfg.macLike.enable = true;
cfg.macLike.lcid = 4;
cfg.macLike.addSubheader = true;
cfg.macLike.includePayloadLength = false;
cfg.macLike.harqProcessRange = [0 15];
cfg.macLike.bsrBucketBytes = [0 256 1024 4096 16384 65535];

cfg.channelObs.enable = true;
cfg.channelObs.exportContextCsv = true;
cfg.channelObs.addReceiverEstimatedToFrontend = false;
cfg.channelObs.burstPad = 64;
cfg.channelObs.cirPowerThresholdDb = -25;

cfg.channel.enableMultipath = true;
cfg.channel.maxDelayRange = [2 12];
cfg.channel.numTapsRange = [2 5];
cfg.channel.randomTapPowerDbRange = [-18 -3];
cfg.channel.cfoNormRange = [-0.06 0.06];
cfg.channel.phaseRange = pi;
cfg.channel.iqGainImbalanceDbRange = [-0.8 0.8];
cfg.channel.iqPhaseImbalanceDegRange = [-5 5];
cfg.channel.dcOffsetPowerDbRange = [-45 -30];
cfg.channel.phaseNoiseStdRange = [0 0.003];
cfg.channel.enablePaNonlinearity = true;
cfg.channel.paRappP = 2.0;
cfg.channel.paBackoffDbRange = [5 12];

cfg.interference.enable = true;
cfg.interference.numBackgroundUERange = [0 3];
cfg.interference.powerOffsetDbRange = [-18 -5];
cfg.interference.timeOffsetRange = [-600 600];
cfg.interference.freqOffsetNormRange = [-0.18 0.18];

cfg.capture.enablePartial = true;
cfg.capture.partialProbability = 0.35;
cfg.capture.windowRatioRange = [0.55 1.00];

cfg.flow.enable = true;
cfg.flow.maxBursts = 24;
cfg.flow.gapZerosRange = [150 1200];
cfg.flow.flowGuardZeros = 400;
cfg.flow.sameNumerologyWithinFlow = true;
cfg.flow.exportFullFlowImage = true;
cfg.flow.logTrueFlowMeta = true;

cfg.projectRoot = '/home/ps/PycharmProjects/researchtopic/pusch_plus';
cfg.sourceRoot = fullfile(cfg.projectRoot, 'datasets', 'source_payloads');

cfg.textMaxBytes  = 1024;
cfg.audioMaxBytes = 12000;
cfg.imageMaxBytes = 30000;
cfg.videoMaxBytes = 60000;

cfg.open5gsManifest.enable = true;
cfg.open5gsManifest.path = '/home/ps/PycharmProjects/researchtopic/5g_matlab_bridge/logs/open5gs_validation_manifest.csv';
cfg.open5gsManifest.requireStatus = 'ok';
cfg.open5gsManifest.minFilesPerClass = 1;

cfg.security.enable = true;
cfg.security.mode = 'pdcp_nea2_like';
cfg.security.normalizePayloadBytes = [];
cfg.security.stripHeaderBytes = 0;

cfg.security.masterKeyHex = '00112233445566778899AABBCCDDEEFF0011223344556677';
cfg.security.K_UPenc_hex = '';
cfg.security.K_NASenc_hex = '';
cfg.security.K_NASint_hex = '';
cfg.security.K_RRCenc_hex = '';
cfg.security.K_RRCint_hex = '';

cfg.security.supi = 'imsi-999700000000001';
cfg.security.suciHomeNetworkPublicKeyId = 1;
cfg.security.suciRoutingIndicator = '0000';
cfg.security.nasKsi = 1;
cfg.security.bearer = 1;
cfg.security.direction = 0;
cfg.security.pdcpSnBits = 18;
cfg.security.pdcpPduPayloadBytes = 1500;
cfg.security.addPdcpHeader = false;
cfg.security.countBase = uint32(baseSeed);

cfg.appEncryption.enable = true;
cfg.appEncryption.mode = 'app_aes_ctr_like';
cfg.appEncryption.keyId = 'app-key-seed2026';
cfg.appEncryption.masterKeyHex = 'A0A1A2A3A4A5A6A7A8A9AAABACADAEAF';
cfg.appEncryption.addAuthTag = true;
cfg.appEncryption.authTagBytes = 16;
cfg.appEncryption.nonceBytes = 12;
cfg.appEncryption.lengthLeakMode = 'app_cipher_length_visible';

cfg.expTag = sprintf('open5gs_flowburst_appenc_pdcp_like_58feat_lengthoracle_nrtoolbox_csi_rrc_mac_seed%d', baseSeed);
cfg.outDir = fullfile(cfg.projectRoot, 'core_pipeline', 'capture_parse_outputs_multiclass', cfg.expTag);
cfg.figDir = fullfile(cfg.outDir, 'figures');

cfg.fusionImages.enable = true;
cfg.fusionImages.outDir = fullfile(cfg.outDir, 'fusion_images');
cfg.fusionImages.imageSize = [224 224];
cfg.fusionImages.spectrumNfft = 512;
cfg.fusionImages.specWinLen = 128;
cfg.fusionImages.specOverlap = 96;
cfg.fusionImages.burstPad = 128;
cfg.fusionImages.targetLen = 4096;
cfg.fusionImages.plotAbsWaveform = true;

cfg.annotatedFigures.enable = true;
cfg.annotatedFigures.maxPerModality = 3;
cfg.annotatedFigures.outDir = fullfile(cfg.outDir, 'annotated_blind_capture_figures');
cfg.annotatedFigures.showTrueParams = true;
cfg.annotatedFigures.nfftSpec = 512;

ensureDir(cfg.outDir);
ensureDir(cfg.figDir);

if cfg.fusionImages.enable
    ensureDir(cfg.fusionImages.outDir);
    ensureDir(fullfile(cfg.fusionImages.outDir, 'waveform'));
    ensureDir(fullfile(cfg.fusionImages.outDir, 'spectrum'));
end

if cfg.annotatedFigures.enable
    ensureDir(cfg.annotatedFigures.outDir);
end

deleteIfExists(fullfile(cfg.figDir, '*.png'));

if isfield(cfg, 'nrPhy') && cfg.nrPhy.enable
    checkNRToolboxAvailability(cfg);
end

cfg.security.keys = derive5GLikeKeys(cfg.security);

if isfield(cfg, 'open5gsManifest') && cfg.open5gsManifest.enable
    sourceIndex = buildSourceFileIndexFromOpen5GSManifest(cfg);
else
    sourceIndex = buildSourceFileIndex(cfg.sourceRoot);
end

annotatedFigState = initAnnotatedFigureState();

results = [];
securityLog = [];
row = 1;
modalities = {'text','audio','image','video'};

for classIdx = 1:numel(modalities)
    modality = modalities{classIdx};
    fprintf('\n===== Modality = %s =====\n', modality);

    for n = 1:cfg.samplesPerClass
        snrDb = cfg.snrRangeDb(1) + rand * diff(cfg.snrRangeDb);
        snrBucket = nearestSnrBucket(snrDb, cfg.snrSummaryBins);

        sampleInfo = sampleRealFileByModality(sourceIndex, modality);
        plainPayload = loadPayloadFromRealFile(sampleInfo, cfg);

        [plainPayload, appMeta] = maybeEncryptPayloadAppLayer5GLike( ...
            plainPayload, cfg, sampleInfo, modality, snrDb, n, row);

        [payload, secMeta] = maybeEncryptPayload5GLike(plainPayload, cfg, sampleInfo, modality, snrDb, n, row);

        [payload, rrcMacMeta] = maybeApplyRrcMacNrLikeAbstraction(payload, cfg, secMeta, row, snrDb);

        if isfield(cfg, 'nrPhy') && cfg.nrPhy.enable
            if isfield(cfg, 'flow') && cfg.flow.enable
                tx = synthesizeFlowFromPayloadNRToolbox(payload, cfg, snrDb, modality, row);
            else
                tx = synthesizePacketFromPayloadNRToolbox(payload, cfg, snrDb, modality, row);
            end
        else
            if isfield(cfg, 'flow') && cfg.flow.enable
                tx = synthesizeFlowFromPayload5GLike(payload, cfg, snrDb, modality, row);
            else
                tx = synthesizePacketFromPayload5GLike(payload, cfg, snrDb, modality, row);
            end
        end

        est = blindReceiveImproved(tx.rxWaveform, cfg);

        channelObs = emptyNRChannelObservability();
        if isfield(cfg, 'channelObs') && cfg.channelObs.enable
            channelObs = extractNRChannelObservability(tx, est, cfg);
        end

        fusionWaveformPath = "";
        fusionSpectrumPath = "";
        if cfg.fusionImages.enable
            try
                estForFusion = est;
                if isfield(cfg, 'flow') && cfg.flow.enable && cfg.flow.exportFullFlowImage
                    estForFusion.burstLeft = 1;
                    estForFusion.burstRight = numel(tx.rxWaveform);
                end
                [fusionWaveformPath, fusionSpectrumPath] = exportFusionBurstSpectrogramImages( ...
                    tx.rxWaveform, modality, snrBucket, row, cfg, estForFusion);
            catch ME
                warning('Fusion image export failed at row %d: %s', row, ME.message);
            end
        end

        [annotatedFigState, annotatedWaveformPath] = maybeExportAnnotatedBlindCaptureFigure( ...
            tx.rxWaveform, tx, est, modality, snrDb, row, cfg, annotatedFigState);

        fftOk = (est.Nfft == tx.Nfft);
        cpOk  = (est.Ncp == tx.Ncp);
        modOk = strcmpi(est.modName, tx.modName);

        if isfield(cfg, 'flow') && cfg.flow.enable

            evalS.ser = NaN;
            evalS.evm = NaN;
        elseif fftOk && cpOk && ~isempty(est.eqSymbols)
            evalS = evaluatePacketRecoveryBasic(est, tx);
        else
            evalS.ser = 1.0;
            evalS.evm = NaN;
        end

        wf = waveformFeatures(tx.rxWaveform);
        bf = blindBurstFeatures(tx.rxWaveform, est, cfg);
        ff = blindFlowBurstFeatures(tx.rxWaveform, cfg);

        results(row).sampleId = row;
        results(row).modality = string(modality);
        results(row).payloadType = string(payload.type);
        results(row).payloadBytes = tx.byteLen;

        results(row).trueSnrDb = snrDb;
        results(row).snrBucket = snrBucket;
        results(row).sourceFileName = string(tx.sourceFileName);
        results(row).sourceFilePath = string(tx.sourceFilePath);
        results(row).sourceSubtype = string(tx.sourceSubtype);
        results(row).waveformImagePath = string(fusionWaveformPath);
        results(row).spectrumImagePath = string(fusionSpectrumPath);
        results(row).annotatedWaveformPath = string(annotatedWaveformPath);

        results(row).open5gsValidated = double(isfield(sampleInfo, 'open5gsValidated') && sampleInfo.open5gsValidated);
        results(row).open5gsReceivedFilePath = getStringField(sampleInfo, 'open5gsReceivedFilePath');
        results(row).open5gsSha256 = getStringField(sampleInfo, 'open5gsSha256');

        results(row).encEnabled = double(payload.isEncrypted);
        results(row).encMode = string(payload.encMode);
        results(row).payloadBytesPlain = payload.payloadBytesPlain;
        results(row).payloadBytesAfterStrip = payload.payloadBytesAfterStrip;
        results(row).payloadBytesTx = payload.payloadBytesTx;

        results(row).appEncEnabled = double(appMeta.appEncEnabled);
        results(row).appEncMode = string(appMeta.appEncMode);
        results(row).appKeyId = string(appMeta.appKeyId);
        results(row).appNonceHex = string(appMeta.appNonceHex);
        results(row).appAuthTagHex = string(appMeta.appAuthTagHex);
        results(row).appPlainBytes = double(appMeta.appPlainBytes);
        results(row).appCipherBytes = double(appMeta.appCipherBytes);
        results(row).payloadVisibleAtGnbAfterPdcp = string(appMeta.payloadVisibleAtGnbAfterPdcp);

        results(row).lengthLeakMode = string(payload.lengthLeakMode);
        results(row).stripHeaderBytes = payload.stripHeaderBytes;
        results(row).pdcpCountStart = double(secMeta.pdcpCountStart);
        results(row).pdcpSnStart = double(secMeta.pdcpSnStart);
        results(row).bearer = double(secMeta.bearer);
        results(row).direction = double(secMeta.direction);
        results(row).suciLike = string(secMeta.suciLike);
        results(row).nasMacHex = string(secMeta.nasMacHex);
        results(row).rrcMacHex = string(secMeta.rrcMacHex);

        results(row).nrPhyEnabled = double(isfield(cfg, 'nrPhy') && cfg.nrPhy.enable);
        results(row).rrcLikeEnabled = double(rrcMacMeta.rrcLikeEnabled);
        results(row).rrcState = string(rrcMacMeta.rrcState);
        results(row).rrcSecurityMode = string(rrcMacMeta.rrcSecurityMode);
        results(row).rrcSrbId = double(rrcMacMeta.rrcSrbId);
        results(row).rrcDrbId = double(rrcMacMeta.rrcDrbId);
        results(row).rrcPduSessionId = double(rrcMacMeta.rrcPduSessionId);
        results(row).rrcQfi = double(rrcMacMeta.rrcQfi);
        results(row).rrcMeasurementConfig = string(rrcMacMeta.rrcMeasurementConfig);

        results(row).macLikeEnabled = double(rrcMacMeta.macLikeEnabled);
        results(row).macLcid = double(rrcMacMeta.macLcid);
        results(row).macHarqProcessId = double(rrcMacMeta.macHarqProcessId);
        results(row).macBsrBucket = double(rrcMacMeta.macBsrBucket);
        results(row).macSubheaderBytes = double(rrcMacMeta.macSubheaderBytes);
        results(row).macPduBytes = double(rrcMacMeta.macPduBytes);

        results(row).rsrpLikeFullDb = double(channelObs.rsrpLikeFullDb);
        results(row).rsrpLikeBurstDb = double(channelObs.rsrpLikeBurstDb);
        results(row).noiseFloorLikeDb = double(channelObs.noiseFloorLikeDb);
        results(row).csiLikeMeanGainDb = double(channelObs.csiLikeMeanGainDb);
        results(row).csiLikeGainStdDb = double(channelObs.csiLikeGainStdDb);
        results(row).csiLikeFreqSelectivity = double(channelObs.csiLikeFreqSelectivity);
        results(row).csiLikePhaseStd = double(channelObs.csiLikePhaseStd);
        results(row).csiLikeNoiseEstimate = double(channelObs.csiLikeNoiseEstimate);
        results(row).cirLikeNumTapsTrue = double(channelObs.cirLikeNumTapsTrue);
        results(row).cirLikeRmsDelayTrue = double(channelObs.cirLikeRmsDelayTrue);
        results(row).cirLikeMaxDelayTrue = double(channelObs.cirLikeMaxDelayTrue);
        results(row).cirLikePowerSpreadDbTrue = double(channelObs.cirLikePowerSpreadDbTrue);
        results(row).cirLikeNumTapsEst = double(channelObs.cirLikeNumTapsEst);
        results(row).cirLikeRmsDelayEst = double(channelObs.cirLikeRmsDelayEst);
        results(row).cirLikeMaxDelayEst = double(channelObs.cirLikeMaxDelayEst);
        results(row).nrTdlDelayProfile = string(channelObs.nrTdlDelayProfile);
        results(row).nrTdlDelaySpread = double(channelObs.nrTdlDelaySpread);
        results(row).nrMaxDopplerShift = double(channelObs.nrMaxDopplerShift);

        results(row).trueNfft = tx.Nfft;
        results(row).estNfft = est.Nfft;
        results(row).trueNcp = tx.Ncp;
        results(row).estNcp = est.Ncp;
        results(row).trueMod = string(tx.modName);
        results(row).estModName = string(est.modName);
        results(row).estMod = modNameToCode(est.modName);
        results(row).mcs = tx.mcs;
        results(row).numPrb = tx.numPrb;
        results(row).numActiveSubcarriers = tx.numActive;
        results(row).numOFDMSymbols = tx.numOFDMSymbols;

        if isfield(tx, 'flowNumBursts')
            results(row).trueFlowNumBursts = tx.flowNumBursts;
            results(row).trueFlowPayloadBitsUsed = tx.flowPayloadBitsUsed;
            results(row).trueFlowPayloadBitsTotal = tx.flowPayloadBitsTotal;
            results(row).trueFlowCoverageRatio = tx.flowCoverageRatio;
        else
            results(row).trueFlowNumBursts = 1;
            results(row).trueFlowPayloadBitsUsed = numel(tx.bits);
            results(row).trueFlowPayloadBitsTotal = numel(tx.bits);
            results(row).trueFlowCoverageRatio = 1;
        end

        results(row).fftOk = fftOk;
        results(row).cpOk = cpOk;
        results(row).modOk = modOk;
        results(row).ser = evalS.ser;
        results(row).evm = evalS.evm;

        results(row).trueStart = tx.startIndex;
        results(row).estStart = est.startIndex;
        results(row).startErr = abs(est.startIndex - tx.startIndex);
        results(row).trueCFO = tx.cfo;
        results(row).estCFO = est.cfo;
        results(row).cfoAbs = abs(est.cfo);

        results(row).cpMetric = est.cpMetric;
        results(row).tfMetric = est.tfMetric;
        results(row).jointScore = est.score;
        results(row).burstLeft = est.burstLeft;
        results(row).burstRight = est.burstRight;
        results(row).burstWidth = est.burstWidth;

        results(row).flowNumBurstsEst = ff.flowNumBurstsEst;
        results(row).flowDutyCycle = ff.flowDutyCycle;
        results(row).flowTotalActiveWidth = ff.flowTotalActiveWidth;
        results(row).flowMeanBurstWidth = ff.flowMeanBurstWidth;
        results(row).flowStdBurstWidth = ff.flowStdBurstWidth;
        results(row).flowMaxBurstWidth = ff.flowMaxBurstWidth;
        results(row).flowMeanGap = ff.flowMeanGap;
        results(row).flowStdGap = ff.flowStdGap;
        results(row).flowBurstEnergyMean = ff.flowBurstEnergyMean;
        results(row).flowBurstEnergyStd = ff.flowBurstEnergyStd;
        results(row).flowBurstEnergySkewness = ff.flowBurstEnergySkewness;
        results(row).flowBurstRateProxy = ff.flowBurstRateProxy;
        results(row).flowEnvelopeEntropy = ff.flowEnvelopeEntropy;

results(row).flowBurstWidthQ25 = ff.flowBurstWidthQ25;

results(row).flowBurstWidthQ50 = ff.flowBurstWidthQ50;

results(row).flowBurstWidthQ75 = ff.flowBurstWidthQ75;

results(row).flowBurstWidthQ90 = ff.flowBurstWidthQ90;

results(row).flowGapQ25 = ff.flowGapQ25;

results(row).flowGapQ50 = ff.flowGapQ50;

results(row).flowGapQ75 = ff.flowGapQ75;

results(row).flowGapQ90 = ff.flowGapQ90;

results(row).flowEnergyQ25 = ff.flowEnergyQ25;

results(row).flowEnergyQ50 = ff.flowEnergyQ50;

results(row).flowEnergyQ75 = ff.flowEnergyQ75;

results(row).flowEnergyQ90 = ff.flowEnergyQ90;

results(row).flowWidthCv = ff.flowWidthCv;

results(row).flowGapCv = ff.flowGapCv;

results(row).flowEnergyCv = ff.flowEnergyCv;

results(row).flowWidthGini = ff.flowWidthGini;

results(row).flowGapGini = ff.flowGapGini;

results(row).flowEnergyGini = ff.flowEnergyGini;

results(row).flowBurstRegularity = ff.flowBurstRegularity;

results(row).flowActiveEdgeRate = ff.flowActiveEdgeRate;

        results(row).burstMean = bf.burstMean;
        results(row).burstStd = bf.burstStd;
        results(row).burstSkewness = bf.burstSkewness;
        results(row).burstKurtosis = bf.burstKurtosis;
        results(row).fftEntropy = bf.fftEntropy;
        results(row).fftPeakRatio = bf.fftPeakRatio;
        results(row).occupiedBandwidthRatio = bf.occupiedBandwidthRatio;
        results(row).tfOccupancyRatio = bf.tfOccupancyRatio;
        results(row).phyThroughputProxy = bf.phyThroughputProxy;
        results(row).estNoisePower = bf.estNoisePower;
        results(row).estSnrFromBurst = bf.estSnrFromBurst;

        results(row).rxSkewness = wf.skewnessVal;
        results(row).rxKurtosis = wf.kurtosisVal;
        results(row).rxPAPR = wf.papr;
        results(row).rxRMS = wf.rmsVal;
        results(row).rxSpecFlatness = wf.specFlatness;
        results(row).specFluxMean = wf.specFluxMean;
        results(row).frameEnergyVar = wf.frameEnergyVar;
        results(row).specCentroidMean = wf.specCentroidMean;
        results(row).specCentroidStd = wf.specCentroidStd;

        securityLog(row).sampleId = row;
        securityLog(row).modality = string(modality);
        securityLog(row).appEncEnabled = double(appMeta.appEncEnabled);
        securityLog(row).appEncMode = string(appMeta.appEncMode);
        securityLog(row).appKeyId = string(appMeta.appKeyId);
        securityLog(row).appNonceHex = string(appMeta.appNonceHex);
        securityLog(row).appAuthTagHex = string(appMeta.appAuthTagHex);
        securityLog(row).appPlainBytes = double(appMeta.appPlainBytes);
        securityLog(row).appCipherBytes = double(appMeta.appCipherBytes);
        securityLog(row).payloadVisibleAtGnbAfterPdcp = string(appMeta.payloadVisibleAtGnbAfterPdcp);
        securityLog(row).suciLike = string(secMeta.suciLike);
        securityLog(row).nasMacHex = string(secMeta.nasMacHex);
        securityLog(row).rrcMacHex = string(secMeta.rrcMacHex);
        securityLog(row).pdcpCountStart = double(secMeta.pdcpCountStart);
        securityLog(row).pdcpSnStart = double(secMeta.pdcpSnStart);
        securityLog(row).bearer = double(secMeta.bearer);
        securityLog(row).direction = double(secMeta.direction);
        securityLog(row).rrcState = string(rrcMacMeta.rrcState);
        securityLog(row).rrcDrbId = double(rrcMacMeta.rrcDrbId);
        securityLog(row).macLcid = double(rrcMacMeta.macLcid);
        securityLog(row).macHarqProcessId = double(rrcMacMeta.macHarqProcessId);
        securityLog(row).macSubheaderBytes = double(rrcMacMeta.macSubheaderBytes);

        if mod(row, 200) == 0
            fprintf('Generated %d samples...\n', row);
        end

        row = row + 1;
    end
end

T = struct2table(results);
S = summarizeResults5GLike(T);

writetable(T, fullfile(cfg.outDir, 'near_blind_packet_results.csv'));
writetable(S, fullfile(cfg.outDir, 'near_blind_summary.csv'));

if ~isempty(securityLog)
    Tsec = struct2table(securityLog);
    writetable(Tsec, fullfile(cfg.outDir, 'security_context_log.csv'));
end

if isfield(cfg, 'channelObs') && cfg.channelObs.enable && cfg.channelObs.exportContextCsv
    channelContextCols = { ...
        'sampleId','modality','snrBucket','nrPhyEnabled', ...
        'rsrpLikeFullDb','rsrpLikeBurstDb','noiseFloorLikeDb', ...
        'csiLikeMeanGainDb','csiLikeGainStdDb','csiLikeFreqSelectivity','csiLikePhaseStd','csiLikeNoiseEstimate', ...
        'cirLikeNumTapsTrue','cirLikeRmsDelayTrue','cirLikeMaxDelayTrue','cirLikePowerSpreadDbTrue', ...
        'cirLikeNumTapsEst','cirLikeRmsDelayEst','cirLikeMaxDelayEst', ...
        'nrTdlDelayProfile','nrTdlDelaySpread','nrMaxDopplerShift', ...
        'rrcLikeEnabled','rrcState','rrcSecurityMode','rrcSrbId','rrcDrbId','rrcPduSessionId','rrcQfi','rrcMeasurementConfig', ...
        'macLikeEnabled','macLcid','macHarqProcessId','macBsrBucket','macSubheaderBytes','macPduBytes', ...
        'mcs','numPrb','numActiveSubcarriers','numOFDMSymbols' ...
    };
    channelContextCols = channelContextCols(ismember(channelContextCols, T.Properties.VariableNames));
    T_channel_context = T(:, channelContextCols);
    writetable(T_channel_context, fullfile(cfg.outDir, 'near_blind_channel_context.csv'));
end

frontendCols = { ...

    'burstMean', ...

    'burstStd', ...

    'burstSkewness', ...

    'burstKurtosis', ...

    'fftEntropy', ...

    'fftPeakRatio', ...

    'occupiedBandwidthRatio', ...

    'tfOccupancyRatio', ...

    'phyThroughputProxy', ...

    'estNoisePower', ...

    'estSnrFromBurst', ...

    'rxSkewness', ...

    'rxKurtosis', ...

    'rxPAPR', ...

    'rxRMS', ...

    'burstWidth', ...

    'jointScore', ...

    'estNcp', ...

    'estMod', ...

    'specFluxMean', ...

    'rxSpecFlatness', ...

    'cfoAbs', ...

    'flowNumBurstsEst', ...

    'flowDutyCycle', ...

    'flowTotalActiveWidth', ...

    'flowMeanBurstWidth', ...

    'flowStdBurstWidth', ...

    'flowMaxBurstWidth', ...

    'flowMeanGap', ...

    'flowStdGap', ...

    'flowBurstEnergyMean', ...

    'flowBurstEnergyStd', ...

    'flowBurstEnergySkewness', ...

    'flowBurstRateProxy', ...

    'flowEnvelopeEntropy', ...

    'flowBurstWidthQ25', ...

    'flowBurstWidthQ50', ...

    'flowBurstWidthQ75', ...

    'flowBurstWidthQ90', ...

    'flowGapQ25', ...

    'flowGapQ50', ...

    'flowGapQ75', ...

    'flowGapQ90', ...

    'flowEnergyQ25', ...

    'flowEnergyQ50', ...

    'flowEnergyQ75', ...

    'flowEnergyQ90', ...

    'flowWidthCv', ...

    'flowGapCv', ...

    'flowEnergyCv', ...

    'flowWidthGini', ...

    'flowGapGini', ...

    'flowEnergyGini', ...

    'flowBurstRegularity', ...

    'flowActiveEdgeRate', ...

    'frameEnergyVar', ...

    'specCentroidMean', ...

    'specCentroidStd' ...

};

evalCols = { ...
    'sampleId','trueSnrDb','snrBucket','modality','payloadType','payloadBytes', ...
    'sourceFileName','sourceFilePath','sourceSubtype', ...
    'waveformImagePath','spectrumImagePath','annotatedWaveformPath', ...
    'open5gsValidated','open5gsReceivedFilePath','open5gsSha256', ...
    'encEnabled','encMode','payloadBytesPlain','payloadBytesAfterStrip','payloadBytesTx', ...
    'lengthLeakMode','stripHeaderBytes', ...
    'pdcpCountStart','pdcpSnStart','bearer','direction','suciLike','nasMacHex','rrcMacHex', ...
    'nrPhyEnabled','rrcLikeEnabled','rrcState','rrcSecurityMode','rrcSrbId','rrcDrbId','rrcPduSessionId','rrcQfi','rrcMeasurementConfig', ...
    'macLikeEnabled','macLcid','macHarqProcessId','macBsrBucket','macSubheaderBytes','macPduBytes', ...
    'rsrpLikeFullDb','rsrpLikeBurstDb','noiseFloorLikeDb','csiLikeMeanGainDb','csiLikeGainStdDb','csiLikeFreqSelectivity','csiLikePhaseStd','csiLikeNoiseEstimate', ...
    'cirLikeNumTapsTrue','cirLikeRmsDelayTrue','cirLikeMaxDelayTrue','cirLikePowerSpreadDbTrue','cirLikeNumTapsEst','cirLikeRmsDelayEst','cirLikeMaxDelayEst', ...
    'trueNfft','trueNcp','trueMod','estModName','mcs','numPrb','numActiveSubcarriers', ...
    'numOFDMSymbols','trueStart','trueCFO','fftOk','cpOk','modOk','ser','evm', ...
    'trueFlowNumBursts','trueFlowPayloadBitsUsed','trueFlowPayloadBitsTotal','trueFlowCoverageRatio' ...
};

if isfield(cfg, 'channelObs') && cfg.channelObs.enable && cfg.channelObs.addReceiverEstimatedToFrontend
    frontendCols = [frontendCols, { ...
        'rsrpLikeBurstDb','noiseFloorLikeDb', ...
        'csiLikeMeanGainDb','csiLikeGainStdDb','csiLikeFreqSelectivity','csiLikePhaseStd', ...
        'cirLikeRmsDelayEst','cirLikeMaxDelayEst' ...
    }];
end

frontendCols = frontendCols(ismember(frontendCols, T.Properties.VariableNames));
evalCols = evalCols(ismember(evalCols, T.Properties.VariableNames));

T_frontend = T(:, frontendCols);
T_eval = T(:, evalCols);

writetable(T_frontend, fullfile(cfg.outDir, 'near_blind_frontend_features.csv'));
writetable(T_eval, fullfile(cfg.outDir, 'near_blind_eval_labels.csv'));

plotSummary5GLike(S, cfg);

fprintf('\nSaved to: %s\n', cfg.outDir);
end

function ensureDir(p)
if ~exist(p, 'dir')
    mkdir(p);
end
end

function deleteIfExists(pattern)
try
    delete(pattern);
catch
end
end

function s = getStringField(st, name)
if isfield(st, name)
    s = string(st.(name));
else
    s = "";
end
end

function sourceIndex = buildSourceFileIndexFromOpen5GSManifest(cfg)
manifestPath = cfg.open5gsManifest.path;
if ~exist(manifestPath, 'file')
    error('Open5GS validation manifest not found: %s', manifestPath);
end

M = readtable(manifestPath, 'TextType', 'string');
requiredCols = {'status','modality','sourceFilePath','sourceFileName','receivedFilePath','payloadBytes','sha256_received'};
for i = 1:numel(requiredCols)
    if ~ismember(requiredCols{i}, M.Properties.VariableNames)
        error('Manifest missing column: %s', requiredCols{i});
    end
end

statusNeed = string(cfg.open5gsManifest.requireStatus);
M = M(strcmpi(M.status, statusNeed), :);
M = M(ismember(lower(M.modality), {'text','audio','image','video'}), :);

[~, ia] = unique(M.sourceFilePath, 'last');
M = M(sort(ia), :);

sourceIndex = struct();
sourceIndex.text  = manifestRowsToFiles(M, 'text');
sourceIndex.audio = manifestRowsToFiles(M, 'audio');
sourceIndex.image = manifestRowsToFiles(M, 'image');
sourceIndex.video = manifestRowsToFiles(M, 'video');

checkManifestClass(sourceIndex.text,  'text',  cfg);
checkManifestClass(sourceIndex.audio, 'audio', cfg);
checkManifestClass(sourceIndex.image, 'image', cfg);
checkManifestClass(sourceIndex.video, 'video', cfg);

fprintf('\n[Open5GS manifest] loaded validated files:\n');
fprintf('  text : %d\n', numel(sourceIndex.text));
fprintf('  audio: %d\n', numel(sourceIndex.audio));
fprintf('  image: %d\n', numel(sourceIndex.image));
fprintf('  video: %d\n', numel(sourceIndex.video));
end

function files = manifestRowsToFiles(M, modality)
mask = strcmpi(M.modality, modality);
T = M(mask, :);
files = struct('filePath', {}, 'fileName', {}, 'ext', {}, 'subtype', {}, ...
               'open5gsValidated', {}, 'open5gsReceivedFilePath', {}, ...
               'open5gsSha256', {}, 'open5gsPayloadBytes', {});

k = 1;
for i = 1:height(T)
    fp = char(T.sourceFilePath(i));
    if ~exist(fp, 'file')
        warning('Validated source file no longer exists, skip: %s', fp);
        continue;
    end
    [~, name, ext] = fileparts(fp);
    files(k).filePath = fp;
    files(k).fileName = char(T.sourceFileName(i));
    if isempty(files(k).fileName)
        files(k).fileName = [name ext];
    end
    files(k).ext = lower(ext);
    files(k).subtype = 'open5gs_validated';
    files(k).open5gsValidated = true;
    files(k).open5gsReceivedFilePath = char(T.receivedFilePath(i));
    files(k).open5gsSha256 = char(T.sha256_received(i));
    files(k).open5gsPayloadBytes = double(T.payloadBytes(i));
    k = k + 1;
end
end

function checkManifestClass(files, modality, cfg)
if numel(files) < cfg.open5gsManifest.minFilesPerClass
    error('Open5GS manifest has too few validated files for %s: %d', modality, numel(files));
end
end

function sourceIndex = buildSourceFileIndex(sourceRoot)
sourceIndex = struct();
sourceIndex.text  = collectFiles(fullfile(sourceRoot, 'text'),  {'.txt'});
sourceIndex.audio = collectFiles(fullfile(sourceRoot, 'audio'), {'.wav','.mp3','.flac','.m4a','.ogg'});
sourceIndex.image = collectFiles(fullfile(sourceRoot, 'image'), {'.jpg','.jpeg','.png','.bmp','.webp'});
sourceIndex.video = collectFiles(fullfile(sourceRoot, 'video'), {'.mp4','.avi','.mov','.mkv','.gif','.webm'});
checkNonEmpty(sourceIndex.text,  'text');
checkNonEmpty(sourceIndex.audio, 'audio');
checkNonEmpty(sourceIndex.image, 'image');
checkNonEmpty(sourceIndex.video, 'video');
end

function files = collectFiles(folderPath, exts)
files = struct('filePath', {}, 'fileName', {}, 'ext', {}, 'subtype', {});
if ~exist(folderPath, 'dir')
    return;
end
allItems = dir(fullfile(folderPath, '**', '*'));
k = 1;
for i = 1:numel(allItems)
    item = allItems(i);
    if item.isdir
        continue;
    end
    [~, name, ext] = fileparts(item.name);
    extLower = lower(ext);
    if ~ismember(extLower, exts)
        continue;
    end
    files(k).filePath = fullfile(item.folder, item.name);
    files(k).fileName = item.name;
    files(k).ext = extLower;
    files(k).subtype = inferSubtypeFromName(name, item.folder);
    k = k + 1;
end
end

function checkNonEmpty(files, modality)
if isempty(files)
    error('No source files found for modality: %s', modality);
end
end

function subtype = inferSubtypeFromName(name, folderPath)
subtype = 'generic';
end

function sampleInfo = sampleRealFileByModality(sourceIndex, modality)
switch lower(modality)
    case 'text'
        files = sourceIndex.text;
    case 'audio'
        files = sourceIndex.audio;
    case 'image'
        files = sourceIndex.image;
    case 'video'
        files = sourceIndex.video;
    otherwise
        error('Unknown modality: %s', modality);
end
idx = randi(numel(files));
sampleInfo = files(idx);
end

function payload = loadPayloadFromRealFile(sampleInfo, cfg)
filePath = sampleInfo.filePath;
[~, ~, ext] = fileparts(filePath);
ext = lower(ext);

switch ext
    case '.txt'
        raw = fileread(filePath);
        bytes = unicode2native(raw, 'UTF-8');
        bytes = uint8(bytes);
        bytes = capPayloadBytes(bytes, cfg.textMaxBytes);
        payload.type = 'text';
        payload.data = bytes(:).';
    otherwise
        fid = fopen(filePath, 'rb');
        if fid < 0
            error('Cannot open file: %s', filePath);
        end
        bytes = fread(fid, inf, '*uint8');
        fclose(fid);
        bytes = bytes(:).';
        if ismember(ext, {'.wav','.mp3','.flac','.m4a','.ogg'})
            bytes = capPayloadBytes(bytes, cfg.audioMaxBytes);
            payload.type = 'audio';
        elseif ismember(ext, {'.jpg','.jpeg','.png','.bmp','.webp'})
            bytes = capPayloadBytes(bytes, cfg.imageMaxBytes);
            payload.type = 'image';
        elseif ismember(ext, {'.mp4','.avi','.mov','.mkv','.gif','.webm'})
            bytes = capPayloadBytes(bytes, cfg.videoMaxBytes);
            payload.type = 'video';
        else
            error('Unsupported file extension: %s', ext);
        end
        payload.data = bytes;
end
payload.sourceFileName = sampleInfo.fileName;
payload.sourceFilePath = sampleInfo.filePath;
payload.subtype = sampleInfo.subtype;
end

function bytesOut = capPayloadBytes(bytesIn, maxBytes)
bytesIn = uint8(bytesIn(:).');
if numel(bytesIn) <= maxBytes
    bytesOut = bytesIn;
else
    bytesOut = bytesIn(1:maxBytes);
end
end

function [payloadOut, appMeta] = maybeEncryptPayloadAppLayer5GLike(plainPayload, cfg, sampleInfo, modality, snrDb, repeatIdx, sampleId)

payloadOut = plainPayload;
plainBytes = uint8(plainPayload.data(:).');

appMeta = initAppLayerMeta();
appMeta.appPlainBytes = numel(plainBytes);
appMeta.appCipherBytes = numel(plainBytes);

if ~isfield(cfg, 'appEncryption') || ~isfield(cfg.appEncryption, 'enable') || ~cfg.appEncryption.enable
    payloadOut.isAppEncrypted = false;
    payloadOut.appEncMode = 'none';
    appMeta.payloadVisibleAtGnbAfterPdcp = 'plain_application_payload';
    return;
end

appCfg = cfg.appEncryption;
appKey = getAppLayerKey(appCfg);

nonceMaterial = sprintf('%s|%s|%s|%.6f|%d|%d|%s', ...
    appCfg.keyId, modality, sampleInfo.fileName, snrDb, repeatIdx, sampleId, plainPayload.type);
nonceHash = sha256Bytes([uint8('APP-NONCE|').'; uint8(nonceMaterial(:)); appKey(:)]);
nonceBytes = nonceHash(1:appCfg.nonceBytes);

switch lower(appCfg.mode)
    case {'app_aes_ctr_like', 'app_ctr_like', 'tls_like'}
        cipherCore = appCtrLikeCryptBytes(plainBytes, appKey, nonceBytes);
    otherwise
        error('Unsupported application-layer encryption mode: %s', appCfg.mode);
end

authTag = uint8([]);
if isfield(appCfg, 'addAuthTag') && appCfg.addAuthTag
    tagHash = sha256Bytes([uint8('APP-AEAD-TAG|').'; appKey(:); nonceBytes(:); cipherCore(:)]);
    tagN = min(numel(tagHash), max(0, appCfg.authTagBytes));
    authTag = tagHash(1:tagN);
end

cipherBytes = [cipherCore(:); authTag(:)];

payloadOut.data = uint8(cipherBytes(:).');
payloadOut.isAppEncrypted = true;
payloadOut.appEncMode = appCfg.mode;
payloadOut.appKeyId = appCfg.keyId;
payloadOut.appNonceHex = bytesToHex(nonceBytes);
payloadOut.appAuthTagHex = bytesToHex(authTag);
payloadOut.appPlainBytes = numel(plainBytes);
payloadOut.appCipherBytes = numel(cipherBytes);

appMeta.appEncEnabled = true;
appMeta.appEncMode = appCfg.mode;
appMeta.appKeyId = appCfg.keyId;
appMeta.appNonceHex = bytesToHex(nonceBytes);
appMeta.appAuthTagHex = bytesToHex(authTag);
appMeta.appPlainBytes = numel(plainBytes);
appMeta.appCipherBytes = numel(cipherBytes);
appMeta.payloadVisibleAtGnbAfterPdcp = 'app_ciphertext_only_no_application_plaintext';
end

function appMeta = initAppLayerMeta()
appMeta.appEncEnabled = false;
appMeta.appEncMode = 'none';
appMeta.appKeyId = 'none';
appMeta.appNonceHex = '';
appMeta.appAuthTagHex = '';
appMeta.appPlainBytes = 0;
appMeta.appCipherBytes = 0;
appMeta.payloadVisibleAtGnbAfterPdcp = 'plain_application_payload';
end

function key = getAppLayerKey(appCfg)
if isfield(appCfg, 'masterKeyHex') && ~isempty(appCfg.masterKeyHex)
    key = hexToBytes(appCfg.masterKeyHex);
else
    seed = uint8(sprintf('default-app-key|%s', appCfg.keyId));
    h = sha256Bytes(seed(:));
    key = h(1:16);
end
if numel(key) ~= 16
    error('Application-layer encryption key must be 16 bytes / 128 bits.');
end
end

function outBytes = appCtrLikeCryptBytes(inBytes, keyBytes, nonceBytes)

    if nargin < 3
        error('appCtrLikeCryptBytes requires inBytes, keyBytes, nonceBytes.');
    end

    originalSize = size(inBytes);
    originalIsRow = isrow(inBytes);

    inCol = uint8(inBytes(:));
    keyCol = uint8(keyBytes(:));
    nonceCol = uint8(nonceBytes(:));

    n = numel(inCol);
    outCol = zeros(n, 1, 'uint8');

    if n == 0
        outBytes = uint8([]);
        return;
    end

    pos = 1;
    counter = uint32(0);

    while pos <= n
        stream = appEncStreamBlockBytes(keyCol, nonceCol, counter, 64);
        stream = uint8(stream(:));

        takeN = min(numel(stream), n - pos + 1);
        idx = pos:(pos + takeN - 1);

        a = uint8(inCol(idx));
        b = uint8(stream(1:takeN));

        outCol(idx) = bitxor(a(:), b(:));

        pos = pos + takeN;
        counter = counter + uint32(1);
    end

    if originalIsRow
        outBytes = reshape(outCol, 1, []);
    else
        outBytes = reshape(outCol, originalSize);
    end
end

function keys = derive5GLikeKeys(secCfg)
master = hexToBytes(secCfg.masterKeyHex);
keys.K_UPenc  = getConfiguredOrDerivedKey(secCfg.K_UPenc_hex,  master, 'K_UPenc');
keys.K_NASenc = getConfiguredOrDerivedKey(secCfg.K_NASenc_hex, master, 'K_NASenc');
keys.K_NASint = getConfiguredOrDerivedKey(secCfg.K_NASint_hex, master, 'K_NASint');
keys.K_RRCenc = getConfiguredOrDerivedKey(secCfg.K_RRCenc_hex, master, 'K_RRCenc');
keys.K_RRCint = getConfiguredOrDerivedKey(secCfg.K_RRCint_hex, master, 'K_RRCint');
end

function key = getConfiguredOrDerivedKey(hexStr, master, label)
if ~isempty(hexStr)
    key = hexToBytes(hexStr);
else
    h = sha256Bytes([uint8(label(:)); uint8(master(:))]);
    key = h(1:16);
end
if numel(key) ~= 16
    error('AES-like key for %s must be 16 bytes.', label);
end
end

function [payload, secMeta] = maybeEncryptPayload5GLike(plainPayload, cfg, sampleInfo, modality, snrDb, repeatIdx, sampleId)
payload = plainPayload;
plainBytes = uint8(plainPayload.data(:).');
payload.payloadBytesPlain = numel(plainBytes);

stripN = 0;
if isfield(cfg.security, 'stripHeaderBytes') && ~isempty(cfg.security.stripHeaderBytes)
    stripN = cfg.security.stripHeaderBytes;
end
payload.stripHeaderBytes = stripN;
if stripN > 0
    plainBytes = stripLeadingBytes(plainBytes, stripN);
end
payload.payloadBytesAfterStrip = numel(plainBytes);

if isempty(cfg.security.normalizePayloadBytes)
    payload.lengthLeakMode = 'realistic_length_leakage';
    bytesWork = plainBytes;
else
    payload.lengthLeakMode = 'fixed_payload_bytes';
    padSeed = [cfg.security.keys.K_UPenc(:); uint8(sampleInfo.fileName(:))];
    bytesWork = normalizePayloadLength(plainBytes, cfg.security.normalizePayloadBytes, padSeed);
end
payload.payloadBytesTx = numel(bytesWork);

secMeta = buildSecurityProcedureMeta(cfg, sampleInfo, modality, snrDb, repeatIdx, sampleId);

if ~cfg.security.enable
    payload.data = bytesWork;
    payload.isEncrypted = false;
    payload.encMode = 'none';
    return;
end

switch lower(cfg.security.mode)
    case 'pdcp_nea2_like'
        [cipherBytes, secMeta] = encryptPayloadBytesPdcpLike(bytesWork, cfg, secMeta);
        payload.data = cipherBytes;
        payload.isEncrypted = true;
        payload.encMode = cfg.security.mode;
    otherwise
        error('Unsupported security mode: %s', cfg.security.mode);
end
end

function secMeta = buildSecurityProcedureMeta(cfg, sampleInfo, modality, snrDb, repeatIdx, sampleId)
metaStr = sprintf('%s|%s|%s|%.3f|%d|%d', cfg.security.supi, modality, sampleInfo.fileName, snrDb, repeatIdx, sampleId);
nonce = sha256Bytes(uint8(metaStr(:)));
nonce = nonce(1:8);

suciMaterial = [ ...
    uint8(cfg.security.supi(:)); ...
    uint8('|SUCI|').'; ...
    nonce(:); ...
    cfg.security.keys.K_NASenc(:) ...
];
suciHash = sha256Bytes(suciMaterial);
secMeta.suciLike = sprintf('suci-0-%s-%d-%s-%s', ...
    cfg.security.suciRoutingIndicator, cfg.security.suciHomeNetworkPublicKeyId, ...
    bytesToHex(nonce), bytesToHex(suciHash(1:10)));

nasPlain = uint8(sprintf('RegistrationRequest|%s|KSI%d|sample%d', secMeta.suciLike, cfg.security.nasKsi, sampleId));
nasCount = uint32(sampleId);
secMeta.nasMacHex = bytesToHex(hmacLike32(cfg.security.keys.K_NASint, nasPlain, nasCount, 0, uint8(0)));

rrcPlain = uint8(sprintf('SecurityModeComplete|SRB1|sample%d', sampleId));
rrcCount = uint32(sampleId + 100000);
secMeta.rrcMacHex = bytesToHex(hmacLike32(cfg.security.keys.K_RRCint, rrcPlain, rrcCount, 0, uint8(1)));

snMax = 2^cfg.security.pdcpSnBits;
secMeta.pdcpSnStart = uint32(mod(sampleId - 1, snMax));
hfn = floor((sampleId - 1) / snMax);
secMeta.pdcpCountStart = uint32(mod(double(cfg.security.countBase) * 100000 + hfn * snMax + double(secMeta.pdcpSnStart), 2^32));
secMeta.bearer = uint8(cfg.security.bearer);
secMeta.direction = uint8(cfg.security.direction);
end

function mac4 = hmacLike32(key, msg, count, direction, bearer)
countBytes = uint32ToBytesBE(count);
input = [uint8('MACI|').'; key(:); countBytes(:); uint8(direction); uint8(bearer); uint8(msg(:))];
h = sha256Bytes(input);
mac4 = h(1:4);
end

function [cipherBytes, secMeta] = encryptPayloadBytesPdcpLike(plainBytes, cfg, secMeta)
plainBytes = uint8(plainBytes(:).');
key = cfg.security.keys.K_UPenc;
pduBytes = cfg.security.pdcpPduPayloadBytes;
if isempty(pduBytes) || pduBytes <= 0
    pduBytes = numel(plainBytes);
end
if isempty(plainBytes)
    cipherBytes = uint8([]);
    return;
end

cipherBytes = zeros(size(plainBytes), 'uint8');
nPdu = ceil(numel(plainBytes) / pduBytes);
snMax = 2^cfg.security.pdcpSnBits;

for p = 1:nPdu
    s = (p-1) * pduBytes + 1;
    e = min(p * pduBytes, numel(plainBytes));
    block = plainBytes(s:e);

    sn = mod(double(secMeta.pdcpSnStart) + (p-1), snMax);
    hfn = floor((double(secMeta.pdcpSnStart) + (p-1)) / snMax);
    count = uint32(mod(double(cfg.security.countBase) * 100000 + hfn * snMax + sn, 2^32));

    ks = nea2LikeKeystreamBytes(key, count, secMeta.bearer, secMeta.direction, numel(block));
    cipherBytes(s:e) = bitxor(block, ks);
end
end

function ksBytes = nea2LikeKeystreamBytes(keyBytes, count, bearer, direction, nBytes)
keyBytes = uint8(keyBytes(:).');
nBlocks = ceil(nBytes / 16);
ks = zeros(1, nBlocks * 16, 'uint8');

try
    cipher = javax.crypto.Cipher.getInstance('AES/ECB/NoPadding');
    keySpec = javax.crypto.spec.SecretKeySpec(int8(keyBytes), 'AES');
    cipher.init(javax.crypto.Cipher.ENCRYPT_MODE, keySpec);

    for i = 0:(nBlocks-1)
        ctr = makeNEA2CounterBlock(count, bearer, direction, uint64(i));
        outJava = cipher.doFinal(int8(ctr));
        out = typecast(int8(outJava), 'uint8');
        ks(i*16+1:(i+1)*16) = out(:).';
    end
catch
    countBytes = uint32ToBytesBE(count);
    seedMaterial = [keyBytes(:); countBytes(:); uint8(bearer); uint8(direction)];
    seed = seedFromBytes(seedMaterial);
    for i = 1:numel(ks)
        seed = xorshift32(seed);
        ks(i) = uint8(bitand(seed, uint32(255)));
    end
end

ksBytes = ks(1:nBytes);
end

function ctr = makeNEA2CounterBlock(count, bearer, direction, blockCounter)
ctr = zeros(1, 16, 'uint8');
ctr(1:4) = uint32ToBytesBE(count);
bearer = uint8(bitand(uint8(bearer), uint8(31)));
direction = uint8(bitand(uint8(direction), uint8(1)));
ctr(5) = bitor(bitshift(bearer, 3), bitshift(direction, 2));
bc = uint64(blockCounter);
for k = 16:-1:9
    ctr(k) = uint8(bitand(bc, uint64(255)));
    bc = bitshift(bc, -8);
end
end

function b = uint32ToBytesBE(x)
x = uint32(x);
b = zeros(1,4,'uint8');
b(1) = uint8(bitand(bitshift(x, -24), 255));
b(2) = uint8(bitand(bitshift(x, -16), 255));
b(3) = uint8(bitand(bitshift(x, -8), 255));
b(4) = uint8(bitand(x, 255));
end

function bytesOut = stripLeadingBytes(bytesIn, stripN)
bytesIn = uint8(bytesIn(:).');
if isempty(bytesIn)
    bytesOut = uint8([]);
elseif stripN <= 0
    bytesOut = bytesIn;
elseif numel(bytesIn) > stripN
    bytesOut = bytesIn(stripN+1:end);
else
    bytesOut = uint8([]);
end
end

function bytesOut = normalizePayloadLength(bytesIn, targetLen, padSeed)
bytesIn = uint8(bytesIn(:).');
if isempty(targetLen) || targetLen <= 0
    bytesOut = bytesIn;
    return;
end
if numel(bytesIn) >= targetLen
    bytesOut = bytesIn(1:targetLen);
    return;
end
state = seedFromBytes(uint8(padSeed(:)));
pad = zeros(1, targetLen - numel(bytesIn), 'uint8');
for i = 1:numel(pad)
    state = xorshift32(state);
    pad(i) = uint8(bitand(state, uint32(255)));
end
bytesOut = [bytesIn pad];
end

function tx = synthesizePacketFromPayload5GLike(payload, cfg, snrDb, modality, sampleId)
Nfft = cfg.fftCandidates(randi(numel(cfg.fftCandidates)));
Ncp = cfg.cpCandidates(randi(numel(cfg.cpCandidates)));

mcs = cfg.ul.mcsSet(randi(numel(cfg.ul.mcsSet)));
modName = mcsToModName(mcs);
if ~ismember(modName, cfg.modCandidates)
    modName = cfg.modCandidates{randi(numel(cfg.modCandidates))};
end
M = modOrder(modName);
bps = log2(M);

payloadBytes = uint8(payload.data(:));
byteLen = numel(payloadBytes);
payloadBits = reshape(de2bi(payloadBytes, 8, 'left-msb').', [], 1);

if cfg.ul.addMacLengthHeader
    lenBits = de2bi(byteLen, 24, 'left-msb').';
    bits = [lenBits(:); payloadBits(:)];
else
    bits = payloadBits(:);
end

if cfg.ul.enableBitScrambling
    bits = scrambleBits5GLike(bits, uint32(sampleId + cfg.ul.rnti + 65537 * cfg.ul.cellId));
end

numOFDMSymbols = randi(cfg.ul.numOFDMSymbolsRange);
maxPrbByNfft = max(1, floor((cfg.ul.activeScRatioMax * Nfft) / 12));
prbMin = max(1, min(cfg.ul.prbRange(1), maxPrbByNfft));
prbMax = max(prbMin, min(cfg.ul.prbRange(2), maxPrbByNfft));
numPrb = randi([prbMin prbMax]);
numActive = min(numPrb * 12, floor(cfg.ul.activeScRatioMax * Nfft));
numActive = max(bps, floor(numActive / 2) * 2);

scIdx = activeSubcarrierIndices(Nfft, numActive);
numSlots = numel(scIdx) * numOFDMSymbols;
needBits = numSlots * bps;

if numel(bits) < needBits
    bitsPad = [bits; zeros(needBits-numel(bits), 1)];
else
    bitsPad = bits(1:needBits);
end

symbols = mapper(bitsPad, modName);
gridData = reshape(symbols, numel(scIdx), numOFDMSymbols);

wave = [];
for k = 1:numOFDMSymbols
    X = zeros(Nfft, 1);
    X(scIdx) = gridData(:, k);
    x = ifft(ifftshift(X), Nfft);
    xcp = [x(end-Ncp+1:end); x];
    wave = [wave; xcp];
end

pre = zeros(cfg.guardZeros + randi([0 120]), 1);
post = zeros(cfg.guardZeros + randi([0 120]), 1);
wave = [pre; wave; post];
startIndex = numel(pre) + 1;

[waveCh, chanMeta] = applyRandomChannelAndImpairments(wave, cfg, Nfft, snrDb);
waveCh = addBackgroundInterference(waveCh, cfg, Nfft, Ncp);
rxFull = addAwgnToTargetSNR(waveCh, snrDb);
[rx, captureMeta] = applyRandomPartialCapture(rxFull, cfg, startIndex, numel(wave) - numel(pre) - numel(post));

startIndexCaptured = startIndex - captureMeta.left + 1;
startIndexCaptured = max(1, startIndexCaptured);

tx.modality = modality;
tx.payloadType = payload.type;
tx.payloadBytes = payloadBytes;
tx.sourceFileName = payload.sourceFileName;
tx.sourceFilePath = payload.sourceFilePath;
tx.sourceSubtype = payload.subtype;
tx.Nfft = Nfft;
tx.Ncp = Ncp;
tx.modName = modName;
tx.mcs = mcs;
tx.numPrb = numPrb;
tx.numActive = numActive;
tx.bits = bits;
tx.bitsPad = bitsPad;
tx.byteLen = byteLen;
tx.numOFDMSymbols = numOFDMSymbols;
tx.scIdx = scIdx;
tx.gridData = gridData;
tx.txWaveform = wave;
tx.rxWaveformFull = rxFull;
tx.rxWaveform = rx;
tx.startIndex = startIndexCaptured;
tx.cfo = chanMeta.cfo;
tx.phase = chanMeta.phase;
tx.channel = chanMeta.h;
tx.snr = snrDb;
tx.captureLeft = captureMeta.left;
tx.captureRight = captureMeta.right;
end

function modName = mcsToModName(mcs)
if mcs <= 9
    modName = 'QPSK';
elseif mcs <= 16
    modName = '16QAM';
else
    modName = '64QAM';
end
end

function bitsOut = scrambleBits5GLike(bitsIn, seed)
bitsIn = double(bitsIn(:) ~= 0);
state = uint32(seed);
if state == 0
    state = uint32(2463534242);
end
scr = zeros(size(bitsIn));
for i = 1:numel(bitsIn)
    state = xorshift32(state);
    scr(i) = double(bitand(state, uint32(1)));
end
bitsOut = xor(bitsIn, scr);
bitsOut = double(bitsOut(:));
end

function [y, meta] = applyRandomChannelAndImpairments(x, cfg, Nfft, snrDb)
x = x(:);
n = (0:numel(x)-1).';

cfo = cfg.channel.cfoNormRange(1) + rand * diff(cfg.channel.cfoNormRange);
phase = (2*rand - 1) * cfg.channel.phaseRange;
y = x .* exp(1j * (2*pi*cfo*n/max(Nfft,1) + phase));

if cfg.channel.enableMultipath
    maxDelay = randi(cfg.channel.maxDelayRange);
    numTaps = randi(cfg.channel.numTapsRange);
    h = zeros(maxDelay+1, 1);
    h(1) = 1;
    used = 0;
    while used < numTaps-1
        d = randi([1 maxDelay]);
        pDb = cfg.channel.randomTapPowerDbRange(1) + rand * diff(cfg.channel.randomTapPowerDbRange);
        h(d+1) = h(d+1) + 10^(pDb/20) * exp(1j*2*pi*rand);
        used = used + 1;
    end
    h = h / sqrt(sum(abs(h).^2) + eps);
    y = conv(y, h, 'same');
else
    h = 1;
end

igDb = cfg.channel.iqGainImbalanceDbRange(1) + rand * diff(cfg.channel.iqGainImbalanceDbRange);
ipDeg = cfg.channel.iqPhaseImbalanceDegRange(1) + rand * diff(cfg.channel.iqPhaseImbalanceDegRange);
g = 10^(igDb/20);
phi = ipDeg*pi/180;
I = real(y) * g;
Q = imag(y) / max(g, eps);
y = I + 1j * (Q*cos(phi) + I*sin(phi));

pnStd = cfg.channel.phaseNoiseStdRange(1) + rand * diff(cfg.channel.phaseNoiseStdRange);
if pnStd > 0
    pn = cumsum(pnStd * randn(size(y)));
    y = y .* exp(1j * pn);
end

p = mean(abs(y).^2) + eps;
dcDb = cfg.channel.dcOffsetPowerDbRange(1) + rand * diff(cfg.channel.dcOffsetPowerDbRange);
dcAmp = sqrt(p * 10^(dcDb/10));
y = y + dcAmp * exp(1j*2*pi*rand);

if cfg.channel.enablePaNonlinearity
    backoff = cfg.channel.paBackoffDbRange(1) + rand * diff(cfg.channel.paBackoffDbRange);
    A = sqrt(mean(abs(y).^2) + eps) * 10^(backoff/20);
    pRapp = cfg.channel.paRappP;
    r = abs(y);
    y = y ./ ((1 + (r./A).^(2*pRapp)).^(1/(2*pRapp)) + eps);
end

meta.cfo = cfo;
meta.phase = phase;
meta.h = h;
end

function y = addBackgroundInterference(y, cfg, Nfft, Ncp)
y = y(:);
if ~cfg.interference.enable
    return;
end
nBg = randi(cfg.interference.numBackgroundUERange);
if nBg <= 0
    return;
end
L = numel(y);
for u = 1:nBg
    bgBits = randi([0 1], 4000, 1);
    bgMod = cfg.ul.modSet{randi(numel(cfg.ul.modSet))};
    bps = log2(modOrder(bgMod));
    bgBits = bgBits(1:floor(numel(bgBits)/bps)*bps);
    bgSym = mapper(bgBits, bgMod);
    numSym = max(4, min(10, floor(numel(bgSym) / max(1, floor(0.4*Nfft)))));
    numAct = min(floor(0.4*Nfft), floor(numel(bgSym)/numSym));
    numAct = max(2, floor(numAct/2)*2);
    bgSym = bgSym(1:numAct*numSym);
    bgGrid = reshape(bgSym, numAct, numSym);
    sc = activeSubcarrierIndices(Nfft, numAct);
    w = [];
    for k = 1:numSym
        X = zeros(Nfft, 1);
        X(sc) = bgGrid(:,k);
        x = ifft(ifftshift(X), Nfft);
        w = [w; x(end-Ncp+1:end); x];
    end
    foff = cfg.interference.freqOffsetNormRange(1) + rand * diff(cfg.interference.freqOffsetNormRange);
    n = (0:numel(w)-1).';
    w = w .* exp(1j*2*pi*foff*n/max(Nfft,1));
    pOffDb = cfg.interference.powerOffsetDbRange(1) + rand * diff(cfg.interference.powerOffsetDbRange);
    scale = sqrt(mean(abs(y).^2)+eps) * 10^(pOffDb/20) / (sqrt(mean(abs(w).^2)+eps));
    w = w * scale;
    off = randi(cfg.interference.timeOffsetRange);
    center = randi([1 L]);
    st = center + off;
    y = addVectorAtOffset(y, w, st);
end
end

function y = addVectorAtOffset(y, w, st)
L = numel(y);
W = numel(w);
stY = max(1, st);
enY = min(L, st + W - 1);
if enY < stY
    return;
end
stW = stY - st + 1;
enW = stW + (enY - stY);
y(stY:enY) = y(stY:enY) + w(stW:enW);
end

function y = addAwgnToTargetSNR(x, snrDb)
x = x(:);
sigPow = mean(abs(x).^2) + eps;
noisePow = sigPow / (10^(snrDb/10));
noise = sqrt(noisePow/2) * (randn(size(x)) + 1j*randn(size(x)));
y = x + noise;
end

function [rx, meta] = applyRandomPartialCapture(rxFull, cfg, startIndex, burstLen)
L = numel(rxFull);
meta.left = 1;
meta.right = L;
if ~cfg.capture.enablePartial || rand > cfg.capture.partialProbability
    rx = rxFull;
    return;
end
ratio = cfg.capture.windowRatioRange(1) + rand * diff(cfg.capture.windowRatioRange);
winLen = max(1024, round(ratio * L));
winLen = min(winLen, L);

burstCenter = startIndex + floor(burstLen/2);
jitter = round((rand - 0.5) * 0.5 * burstLen);
center = min(max(1, burstCenter + jitter), L);
left = center - floor(winLen/2);
left = min(max(1, left), L - winLen + 1);
right = left + winLen - 1;
rx = rxFull(left:right);
meta.left = left;
meta.right = right;
end

function est = blindReceiveImproved(rx, cfg)
burst = coarseBurstLocate(rx);
best.score = -inf;
best.Nfft = NaN;
best.Ncp = NaN;
best.start = 1;
best.cfo = 0;
best.cpMetric = 0;
best.tfMetric = 0;

for Nfft = cfg.fftCandidates
    for Ncp = cfg.cpCandidates
        [score, startIdx, cfoHat, cpMetric, tfMetric] = scoreHypothesisImproved(rx, burst, Nfft, Ncp);
        if score > best.score
            best.score = score;
            best.Nfft = Nfft;
            best.Ncp = Ncp;
            best.start = startIdx;
            best.cfo = cfoHat;
            best.cpMetric = cpMetric;
            best.tfMetric = tfMetric;
        end
    end
end

Nfft = best.Nfft;
Ncp = best.Ncp;
startIdx = best.start;
n = (0:length(rx)-1).';
rxC = rx .* exp(-1j*2*pi*best.cfo*n/max(Nfft,1));

symLen = Nfft + Ncp;
available = length(rxC) - startIdx + 1;
numSyms = floor(available / symLen);
eqSymbols = [];
rawSymbols = [];
scIdx = activeSubcarrierIndices(Nfft, floor(0.6*Nfft));

if numSyms >= 3
    allSc = zeros(numel(scIdx), numSyms);
    for k = 1:numSyms
        st = startIdx + (k-1)*symLen;
        seg = rxC(st+Ncp : st+Ncp+Nfft-1);
        X = fftshift(fft(seg, Nfft));
        allSc(:,k) = X(scIdx);
    end
    powSc = sqrt(mean(abs(allSc).^2, 2) + 1e-8);
    eqSymbols0 = allSc ./ powSc;
    eqSymbols0 = eqSymbols0 / sqrt(mean(abs(eqSymbols0(:)).^2) + 1e-12);
    modName0 = classifyModulation(eqSymbols0, cfg.modCandidates);
    refSymbols = projectToNearestConstellation(eqSymbols0, modName0);
    HhatDD = mean(allSc ./ (refSymbols + 1e-8), 2);
    HhatDD(abs(HhatDD) < 1e-8) = 1;
    eqSymbols = allSc ./ HhatDD;
    eqSymbols = eqSymbols / sqrt(mean(abs(eqSymbols(:)).^2) + 1e-12);
    rawSymbols = allSc;
else
    modName0 = 'Unknown';
end

if ~isempty(eqSymbols)
    modName = classifyModulation(eqSymbols, cfg.modCandidates);
else
    modName = modName0;
end

est.Nfft = Nfft;
est.Ncp = Ncp;
est.startIndex = startIdx;
est.cfo = best.cfo;
est.eqSymbols = eqSymbols;
est.rawSymbols = rawSymbols;
est.modName = modName;
est.score = best.score;
est.cpMetric = best.cpMetric;
est.tfMetric = best.tfMetric;
est.burstLeft = burst.left;
est.burstRight = burst.right;
est.burstWidth = burst.width;
end

function burst = coarseBurstLocate(rx)
p = abs(rx(:)).^2;
env = movmean(p, 64);
medv = median(env);
madv = mad(env, 1);
thr = medv + 3.0*madv;
active = env > thr;
active = conv(double(active), ones(33,1), 'same') > 0;
d = diff([0; active(:); 0]);
starts = find(d == 1);
ends = find(d == -1) - 1;
if isempty(starts)
    [~, idx] = max(env);
    left = max(1, idx - 512);
    right = min(length(rx), idx + 512);
else
    widths = ends - starts + 1;
    [~, id] = max(widths);
    left = starts(id);
    right = ends(id);
end
burst.left = left;
burst.right = right;
burst.width = right - left + 1;
end

function [score, bestStart, cfoHat, cpMetricBest, tfMetricBest] = scoreHypothesisImproved(rx, burst, Nfft, Ncp)
symLen = Nfft + Ncp;
coarseLeft = max(1, burst.left - symLen);
coarseRight = min(length(rx)-5*symLen, burst.left + symLen);
if coarseRight <= coarseLeft
    score = -inf;
    bestStart = 1;
    cfoHat = 0;
    cpMetricBest = 0;
    tfMetricBest = 0;
    return;
end
coarseStride = max(1, floor(symLen/8));
candStarts = coarseLeft:coarseStride:coarseRight;
bestScore = -inf;
bestStart = candStarts(1);
bestPhase = 0;
cpMetricBest = 0;
tfMetricBest = 0;
for s = candStarts
    [cpMetric, phaseVal] = localCPMetric(rx, s, symLen, Nfft, Ncp);
    tfMetric = localTFMetric(rx, s, Nfft, Ncp);
    joint = 0.7*cpMetric + 0.3*tfMetric;
    if joint > bestScore
        bestScore = joint;
        bestStart = s;
        bestPhase = phaseVal;
        cpMetricBest = cpMetric;
        tfMetricBest = tfMetric;
    end
end
fineLeft = max(1, bestStart - coarseStride);
fineRight = min(length(rx)-5*symLen, bestStart + coarseStride);
for s = fineLeft:fineRight
    [cpMetric, phaseVal] = localCPMetric(rx, s, symLen, Nfft, Ncp);
    tfMetric = localTFMetric(rx, s, Nfft, Ncp);
    joint = 0.7*cpMetric + 0.3*tfMetric;
    if joint > bestScore
        bestScore = joint;
        bestStart = s;
        bestPhase = phaseVal;
        cpMetricBest = cpMetric;
        tfMetricBest = tfMetric;
    end
end
score = bestScore;
cfoHat = bestPhase / (2*pi);
end

function [metric, phaseVal] = localCPMetric(rx, s, symLen, Nfft, Ncp)
numEval = min(8, floor((length(rx)-s+1)/symLen) - 1);
if numEval < 2
    metric = 0;
    phaseVal = 0;
    return;
end
corrs = zeros(numEval,1);
for k = 1:numEval
    st = s + (k-1)*symLen;
    a = rx(st:st+Ncp-1);
    b = rx(st+Nfft:st+Nfft+Ncp-1);
    corrs(k) = sum(conj(a).*b) / (sqrt(sum(abs(a).^2)*sum(abs(b).^2)) + 1e-12);
end
metric = abs(mean(corrs));
phaseVal = angle(mean(corrs));
end

function tfMetric = localTFMetric(rx, s, Nfft, Ncp)
symLen = Nfft + Ncp;
numEval = min(4, floor((length(rx)-s+1)/symLen));
if numEval < 2
    tfMetric = 0;
    return;
end
acc = zeros(Nfft,1);
for k = 1:numEval
    st = s + (k-1)*symLen;
    seg = rx(st+Ncp : st+Ncp+Nfft-1);
    X = abs(fftshift(fft(seg, Nfft))).^2;
    acc = acc + X;
end
acc = acc / numEval;
center = floor(Nfft/2) + 1;
w = floor(0.6*Nfft/2);
inBand = acc(center-w:center+w);
outBand = [acc(1:max(1,center-w-1)); acc(min(Nfft,center+w+1):end)];
ratio = mean(inBand) / (mean(outBand) + 1e-12);
tfMetric = min(1.0, log1p(ratio)/3.0);
end

function bf = blindBurstFeatures(rx, est, cfg)
x = rx(:);
L = numel(x);
left = max(1, round(est.burstLeft));
right = min(L, round(est.burstRight));
if right <= left
    left = 1;
    right = L;
end
xb = x(left:right);
mag = abs(xb);
if isempty(mag)
    mag = 0;
end
m = mean(mag);
s = std(mag) + 1e-12;
bf.burstMean = m;
bf.burstStd = s;
bf.burstSkewness = mean(((mag - m) ./ s).^3);
bf.burstKurtosis = mean(((mag - m) ./ s).^4);

N = 1024;
if numel(xb) < 8
    xbF = [xb; zeros(8-numel(xb),1)];
else
    xbF = xb;
end
P = abs(fftshift(fft(xbF, N))).^2 + 1e-12;
prob = P / sum(P);
bf.fftEntropy = -sum(prob .* log2(prob + 1e-12)) / log2(numel(prob));
bf.fftPeakRatio = max(P) / (mean(P) + 1e-12);
pDb = 10*log10(P + 1e-12);
bf.occupiedBandwidthRatio = mean(pDb > max(pDb) - 20);

winLen = min(128, max(32, floor(numel(xbF)/2)));
overlap = min(96, winLen-1);
try
    [S,~,~] = spectrogram(xbF, hann(winLen,'periodic'), overlap, 256, 'centered');
catch
    S = localSpectrogramMatrixForFusion(xbF, winLen, overlap, 256);
end
PT = abs(S).^2 + 1e-12;
PTdB = 10*log10(PT);
bf.tfOccupancyRatio = mean(PTdB(:) > max(PTdB(:)) - 25);
bf.phyThroughputProxy = double(est.burstWidth) * bf.tfOccupancyRatio * bf.occupiedBandwidthRatio;

pad = 64;
noiseIdx = true(L,1);
noiseIdx(max(1,left-pad):min(L,right+pad)) = false;
noiseSamples = x(noiseIdx);
if numel(noiseSamples) < 16
    noisePow = median(abs(x).^2) + 1e-12;
else
    noisePow = median(abs(noiseSamples).^2) + 1e-12;
end
sigPow = mean(abs(xb).^2) + 1e-12;
bf.estNoisePower = noisePow;
bf.estSnrFromBurst = 10*log10(max(sigPow - noisePow, 1e-12) / noisePow);
bf.estSnrFromBurst = min(max(bf.estSnrFromBurst, -30), 60);
end

function wf = waveformFeatures(rx)
rx = rx(:);
mag = abs(rx);
p = mag.^2;
rmsPow = mean(p) + 1e-12;
wf.rmsVal = sqrt(rmsPow);
wf.papr = 10*log10(max(p) / rmsPow);
N = 4096;
S = abs(fftshift(fft(rx, N))).^2 + 1e-12;
wf.specFlatness = exp(mean(log(S))) / mean(S);
magc = mag - mean(mag);
magStd = std(magc) + 1e-12;
wf.skewnessVal = mean((magc ./ magStd).^3);
wf.kurtosisVal = mean((magc ./ magStd).^4);

frameLen = 256;
hop = 128;
nFrames = floor((length(rx) - frameLen) / hop) + 1;
if nFrames < 2
    wf.frameEnergyVar = 0;
    wf.specCentroidMean = 0;
    wf.specCentroidStd = 0;
    wf.specFluxMean = 0;
    return;
end
win = hann(frameLen, 'periodic');
freqAxis = (0:frameLen-1)' / frameLen;
frameEnergy = zeros(nFrames,1);
specCentroid = zeros(nFrames,1);
specFlux = zeros(nFrames-1,1);
prevSpec = [];
for i = 1:nFrames
    st = (i-1)*hop + 1;
    seg = rx(st:st+frameLen-1) .* win;
    frameEnergy(i) = mean(abs(seg).^2);
    X = abs(fft(seg, frameLen)).^2 + 1e-12;
    Xn = X / sum(X);
    specCentroid(i) = sum(freqAxis .* Xn);
    if ~isempty(prevSpec)
        specFlux(i-1) = mean((Xn - prevSpec).^2);
    end
    prevSpec = Xn;
end
wf.frameEnergyVar = var(frameEnergy, 1);
wf.specCentroidMean = mean(specCentroid);
wf.specCentroidStd = std(specCentroid, 1);
wf.specFluxMean = mean(specFlux);
end

function evalS = evaluatePacketRecoveryBasic(est, tx)
numCommonRows = min(size(est.eqSymbols,1), size(tx.gridData,1));
numCommonCols = min(size(est.eqSymbols,2), size(tx.gridData,2));
if numCommonRows <= 0 || numCommonCols <= 0
    evalS.ser = 1;
    evalS.evm = NaN;
    return;
end
rxSym = est.eqSymbols(1:numCommonRows, 1:numCommonCols);
txSym = tx.gridData(1:numCommonRows, 1:numCommonCols);
phi = angle(sum(conj(rxSym(:)).*txSym(:)));
rxSym = rxSym * exp(-1j*phi);
scale = sqrt(mean(abs(txSym(:)).^2) / (mean(abs(rxSym(:)).^2) + 1e-12));
rxSym = rxSym * scale;
txBits = demapperNearest(txSym(:), tx.modName);
rxBits = demapperNearest(rxSym(:), tx.modName);
bps = log2(modOrder(tx.modName));
txIdx = bi2de(reshape(txBits, bps, []).', 'left-msb');
rxIdx = bi2de(reshape(rxBits, bps, []).', 'left-msb');
evalS.ser = mean(txIdx ~= rxIdx);
evalS.evm = sqrt(mean(abs(rxSym(:)-txSym(:)).^2) / (mean(abs(txSym(:)).^2)+1e-12));
end

function S = summarizeResults5GLike(T)
snrBins = unique(T.snrBucket);
modalities = unique(T.modality);
rows = {};
for c = 1:numel(modalities)
    cls = modalities(c);
    for i = 1:numel(snrBins)
        s = snrBins(i);
        mask = (T.snrBucket == s) & strcmp(T.modality, cls);
        if ~any(mask)
            continue;
        end
        rows(end+1,:) = { ...
            s, cls, sum(mask), ...
            mean(T.fftOk(mask)), mean(T.cpOk(mask)), mean(T.modOk(mask)), ...
            mean(T.ser(mask), 'omitnan'), mean(T.evm(mask), 'omitnan'), ...
            mean(T.estSnrFromBurst(mask), 'omitnan'), mean(T.jointScore(mask), 'omitnan')};
    end
end
S = cell2table(rows, 'VariableNames', ...
    {'snrBucket','modality','n','fftAcc','cpAcc','modAcc','serMean','evmMean','estSnrMean','jointScoreMean'});
end

function plotSummary5GLike(summary, cfg)
if isempty(summary)
    return;
end
classes = {'text','audio','image','video'};
markers = {'-o','-s','-d','-^'};
metrics = {'fftAcc','cpAcc','modAcc','serMean','estSnrMean','jointScoreMean'};
ylabels = {'FFT accuracy','CP accuracy','Modulation accuracy','SER mean','Estimated SNR from burst','Joint score'};
for m = 1:numel(metrics)
    figure('Color','w');
    for i = 1:numel(classes)
        mask = strcmp(summary.modality, classes{i});
        if any(mask)
            plot(summary.snrBucket(mask), summary.(metrics{m})(mask), markers{i}, 'LineWidth', 1.8); hold on;
        end
    end
    grid on;
    xlabel('True SNR bucket, eval only (dB)');
    ylabel(ylabels{m});
    legend(classes{:}, 'Location', 'best');
    title(sprintf('%s (%s)', ylabels{m}, cfg.expTag), 'Interpreter', 'none');
    saveas(gcf, fullfile(cfg.figDir, sprintf('%s.png', metrics{m})));
    close(gcf);
end
end

function idx = activeSubcarrierIndices(Nfft, numActive)
half = floor(numActive/2);
center = floor(Nfft/2)+1;
left = (center-half):(center-1);
right = (center+1):(center+half);
idx = [left right].';
idx = idx(idx >= 1 & idx <= Nfft);
if numel(idx) > numActive
    idx = idx(1:numActive);
end
end

function M = modOrder(modName)
switch upper(char(modName))
    case 'QPSK'
        M = 4;
    case '16QAM'
        M = 16;
    case '64QAM'
        M = 64;
    otherwise
        error('Unsupported modulation: %s', modName);
end
end

function code = modNameToCode(modName)
switch upper(char(modName))
    case 'QPSK'
        code = 1;
    case '16QAM'
        code = 2;
    case '64QAM'
        code = 3;
    otherwise
        code = 0;
end
end

function const = idealConstellation(modName)
switch upper(char(modName))
    case 'QPSK'
        const = [1+1j; 1-1j; -1+1j; -1-1j] / sqrt(2);
    case '16QAM'
        a = [-3 -1 1 3];
        [I,Q] = meshgrid(a,a);
        const = I(:) + 1j*Q(:);
        const = const / sqrt(mean(abs(const).^2));
    case '64QAM'
        a = [-7 -5 -3 -1 1 3 5 7];
        [I,Q] = meshgrid(a,a);
        const = I(:) + 1j*Q(:);
        const = const / sqrt(mean(abs(const).^2));
    otherwise
        error('Unsupported modulation');
end
end

function modName = classifyModulation(eqSymbols, modCandidates)
bestErr = inf;
modName = modCandidates{1};
for i = 1:numel(modCandidates)
    name = modCandidates{i};
    const = idealConstellation(name);
    x = eqSymbols(:);
    dmin = inf(size(x));
    for k = 1:numel(const)
        dmin = min(dmin, abs(x - const(k)).^2);
    end
    err = mean(dmin);
    if err < bestErr
        bestErr = err;
        modName = name;
    end
end
end

function refSymbols = projectToNearestConstellation(symMat, modName)
const = idealConstellation(modName);
x = symMat(:);
ref = zeros(size(x));
for i = 1:numel(x)
    [~, idx] = min(abs(x(i) - const));
    ref(i) = const(idx);
end
refSymbols = reshape(ref, size(symMat));
end

function sym = mapper(bits, modName)
bits = double(bits(:));
bps = log2(modOrder(modName));
bits = bits(1:floor(numel(bits)/bps)*bps);
switch upper(char(modName))
    case 'QPSK'
        b = reshape(bits, 2, []).';
        I = 1 - 2*b(:,1);
        Q = 1 - 2*b(:,2);
        sym = complex(I,Q) / sqrt(2);
    case '16QAM'
        b = reshape(bits, 4, []).';
        I = pamGray(b(:,1:2), 4);
        Q = pamGray(b(:,3:4), 4);
        sym = complex(I,Q);
        sym = sym / sqrt(mean(abs(sym).^2));
    case '64QAM'
        b = reshape(bits, 6, []).';
        I = pamGray(b(:,1:3), 8);
        Q = pamGray(b(:,4:6), 8);
        sym = complex(I,Q);
        sym = sym / sqrt(mean(abs(sym).^2));
    otherwise
        error('Unsupported modulation');
end
end

function a = pamGray(b, order)
d = bi2de(b, 'left-msb');
if order == 4
    levels = [-3 -1 3 1];
elseif order == 8
    levels = [-7 -5 -1 -3 7 5 1 3];
else
    error('Unsupported PAM order');
end
a = levels(d + 1).';
end

function bits = demapperNearest(sym, modName)
const = idealConstellation(modName);
M = numel(const);
bps = log2(M);
sym = sym(:);
bits = zeros(numel(sym)*bps, 1, 'double');
for i = 1:numel(sym)
    [~, idx] = min(abs(sym(i)-const));
    idx0 = idx - 1;
    bits((i-1)*bps+1:i*bps) = de2bi(idx0, bps, 'left-msb').';
end
end

function bucket = nearestSnrBucket(snrDb, bins)
[~, idx] = min(abs(bins - snrDb));
bucket = bins(idx);
end

function [waveformPath, spectrogramPath] = exportFusionBurstSpectrogramImages(rx, modality, snrBucket, sampleId, cfg, est)
waveformPath = "";
spectrogramPath = "";
if isempty(rx) || ~isfield(cfg, 'fusionImages') || ~cfg.fusionImages.enable
    return;
end
x = rx(:);
modality = char(modality);
imgSize = cfg.fusionImages.imageSize;
waveDir = fullfile(cfg.fusionImages.outDir, 'waveform', modality);
specDir = fullfile(cfg.fusionImages.outDir, 'spectrum', modality);
ensureDir(waveDir);
ensureDir(specDir);
waveformPath = fullfile(waveDir, sprintf('sample_%06d_snrbin%d_waveform.png', sampleId, snrBucket));
spectrogramPath = fullfile(specDir, sprintf('sample_%06d_snrbin%d_spectrogram.png', sampleId, snrBucket));
[left, right] = selectFusionBurstRegion(x, est);
burstPad = cfg.fusionImages.burstPad;
left = max(1, left - burstPad);
right = min(numel(x), right + burstPad);
if right <= left
    left = 1;
    right = numel(x);
end
xb = x(left:right);
xb = resizeComplexVectorForFusion(xb, cfg.fusionImages.targetLen);

if cfg.fusionImages.plotAbsWaveform
    y = abs(xb);
else
    y = real(xb);
end
y = y(:);
y(~isfinite(y)) = 0;
y = y - min(y);
y = y ./ (max(y) + eps);
waveImg = vectorCurveToGrayImageForFusion(y, imgSize);
imwrite(waveImg, waveformPath);

nfft = min(max(256, round(cfg.fusionImages.spectrumNfft)), 1024);
winLen = min(cfg.fusionImages.specWinLen, max(32, floor(numel(xb) / 2)));
overlap = min(cfg.fusionImages.specOverlap, winLen - 1);
try
    win = hann(winLen, 'periodic');
catch
    win = hamming(winLen);
end
try
    [S, ~, ~] = spectrogram(xb, win, overlap, nfft, 'centered');
catch
    try
        [S, ~, ~] = spectrogram(xb, win, overlap, nfft);
        S = fftshift(S, 1);
    catch
        S = localSpectrogramMatrixForFusion(xb, winLen, overlap, nfft);
    end
end
P = abs(S).^2;
P = 10 * log10(P + 1e-12);
pMax = max(P(:));
P = P - pMax;
P(P < -60) = -60;
P = (P + 60) / 60;
P = min(max(P, 0), 1);
P = imresize(P, imgSize);
P = uint8(255 * P);
imwrite(P, spectrogramPath);
end

function [left, right] = selectFusionBurstRegion(x, est)
left = [];
right = [];
if nargin >= 2 && isstruct(est) && isfield(est, 'burstLeft') && isfield(est, 'burstRight')
    bL = est.burstLeft;
    bR = est.burstRight;
    if ~isempty(bL) && ~isempty(bR) && isnumeric(bL) && isnumeric(bR) && ...
            isscalar(bL) && isscalar(bR) && isfinite(bL) && isfinite(bR) && ...
            bL >= 1 && bR <= numel(x) && bR > bL
        left = round(bL);
        right = round(bR);
    end
end
if isempty(left) || isempty(right)
    [left, right] = detectFusionBurstRegion(x);
end
end

function [left, right] = detectFusionBurstRegion(x)
x = x(:);
p = abs(x).^2;
if numel(p) < 32
    left = 1;
    right = numel(x);
    return;
end
env = movmean(p, 64);
medv = median(env);
madv = mad(env, 1);
thr = medv + 2.5 * madv;
active = env > thr;
active = conv(double(active), ones(33,1), 'same') > 0;
d = diff([0; active(:); 0]);
starts = find(d == 1);
ends = find(d == -1) - 1;
if isempty(starts)
    [~, idx] = max(env);
    halfLen = min(2048, floor(numel(x) / 2));
    left = max(1, idx - halfLen);
    right = min(numel(x), idx + halfLen);
    return;
end
widths = ends - starts + 1;
[~, id] = max(widths);
left = starts(id);
right = ends(id);
end

function y = resizeComplexVectorForFusion(x, targetLen)
x = x(:);
if isempty(x)
    y = complex(zeros(targetLen, 1));
    return;
end
if numel(x) == targetLen
    y = x;
    return;
end
oldIdx = linspace(0, 1, numel(x));
newIdx = linspace(0, 1, targetLen);
yr = interp1(oldIdx, real(x), newIdx, 'linear', 'extrap');
yi = interp1(oldIdx, imag(x), newIdx, 'linear', 'extrap');
y = complex(yr(:), yi(:));
end

function img = vectorCurveToGrayImageForFusion(v, imgSize)
H = imgSize(1);
W = imgSize(2);
v = double(v(:));
v(~isfinite(v)) = 0;
if numel(v) < 2
    v = [v; v];
end
xOld = linspace(1, W, numel(v));
xNew = 1:W;
vq = interp1(xOld, v, xNew, 'linear', 'extrap');
lo = prctile(vq, 1);
hi = prctile(vq, 99);
if hi <= lo
    lo = min(vq);
    hi = max(vq);
end
if hi <= lo
    yNorm = 0.5 * ones(size(vq));
else
    yNorm = (vq - lo) ./ (hi - lo);
    yNorm = min(max(yNorm, 0), 1);
end
yPix = round((1 - yNorm) * (H - 1)) + 1;
yPix = min(max(yPix, 1), H);
img = uint8(255 * ones(H, W));
for x = 1:W
    y = yPix(x);
    img(max(1, y-1):min(H, y+1), x) = 0;
    if x > 1
        yPrev = yPix(x-1);
        y1 = min(yPrev, y);
        y2 = max(yPrev, y);
        img(max(1, y1):min(H, y2), x) = 0;
    end
end
end

function X = localSpectrogramMatrixForFusion(x, winLen, overlap, nfft)
x = x(:);
hop = max(1, winLen - overlap);
nFrames = max(1, 1 + floor((numel(x) - winLen) / hop));
try
    w = hann(winLen, 'periodic');
catch
    w = hamming(winLen);
end
X = zeros(nfft, nFrames);
for k = 1:nFrames
    idx0 = (k - 1) * hop + 1;
    idx1 = min(numel(x), idx0 + winLen - 1);
    seg = complex(zeros(winLen, 1));
    tmp = x(idx0:idx1);
    seg(1:numel(tmp)) = tmp;
    seg = seg .* w;
    X(:, k) = fftshift(fft(seg, nfft));
end
end

function state = initAnnotatedFigureState()
state = struct();
state.text = 0;
state.audio = 0;
state.image = 0;
state.video = 0;
end

function [state, outPath] = maybeExportAnnotatedBlindCaptureFigure(rx, tx, est, modality, snrDb, sampleId, cfg, state)
outPath = "";
if ~isfield(cfg, 'annotatedFigures') || ~cfg.annotatedFigures.enable
    return;
end
modality = char(modality);
if ~isfield(state, modality)
    state.(modality) = 0;
end
if state.(modality) >= cfg.annotatedFigures.maxPerModality
    return;
end
try
    outDir = fullfile(cfg.annotatedFigures.outDir, modality);
    ensureDir(outDir);
    outPath = fullfile(outDir, sprintf('sample_%06d_%s_annotated_capture.png', sampleId, modality));
    exportAnnotatedBlindCaptureFigure(rx, tx, est, modality, snrDb, sampleId, cfg, outPath);
    state.(modality) = state.(modality) + 1;
catch ME
    warning('Annotated blind capture figure export failed at sample %d: %s', sampleId, ME.message);
    outPath = "";
end
end

function exportAnnotatedBlindCaptureFigure(rx, tx, est, modality, snrDb, sampleId, cfg, outPath)
x = rx(:);
N = numel(x);
left = max(1, round(est.burstLeft));
right = min(N, round(est.burstRight));
if right <= left
    left = 1;
    right = N;
end
xb = x(left:right);

fig = figure('Visible','off','Color','w','Position',[80 80 1300 760]);

subplot(3,1,1);
plot(abs(x), 'k', 'LineWidth', 0.8); hold on;
yl = ylim;
patch([left right right left], [yl(1) yl(1) yl(2) yl(2)], [0.90 0.95 1.00], ...
    'FaceAlpha', 0.35, 'EdgeColor', 'none');
plot(abs(x), 'k', 'LineWidth', 0.8);
xline(left, '--b', 'burstLeft');
xline(right, '--b', 'burstRight');
grid on;
xlabel('Sample Index');
ylabel('|r[n]|');
title(sprintf('Near-blind captured waveform | sample=%d | modality=%s', sampleId, modality), 'Interpreter','none');

subplot(3,1,2);

xbSpec = xb(:);

if isempty(xbSpec)
    xbSpec = complex(zeros(64, 1));
end

minSpecLen = 64;
if numel(xbSpec) < minSpecLen
    xbSpec = [xbSpec; complex(zeros(minSpecLen - numel(xbSpec), 1))];
end

nfft = 512;
if isfield(cfg.annotatedFigures, 'nfftSpec')
    nfft = cfg.annotatedFigures.nfftSpec;
end
nfft = max(128, round(nfft));

winLen = min(128, max(16, floor(numel(xbSpec) / 2)));
winLen = min(winLen, numel(xbSpec));

overlap = min(96, winLen - 1);
overlap = max(0, overlap);

try
    win = hann(winLen, 'periodic');
catch
    win = hamming(winLen);
end

try
    [S,F,T] = spectrogram(xbSpec, win, overlap, nfft, 'centered');
catch
    try
        [S,F,T] = spectrogram(xbSpec, win, overlap, nfft);
        S = fftshift(S, 1);
    catch
        S = localSpectrogramMatrixForFusion(xbSpec, winLen, overlap, nfft);
        F = linspace(-0.5, 0.5, size(S, 1));
        T = 1:size(S, 2);
    end
end

P = 20 * log10(abs(S) + 1e-12);
imagesc(T, F, P);
axis xy;
colormap(gca, parula);
colorbar;
xlabel('Time Frame');
ylabel('Normalized Frequency');
title('Effective burst spectrogram');

subplot(3,1,3);
axis off;
trueInfo = '';
if isfield(cfg.annotatedFigures, 'showTrueParams') && cfg.annotatedFigures.showTrueParams
    trueInfo = sprintf('True: SNR=%.2f dB, Nfft=%d, Ncp=%d, Mod=%s, CFO=%.4f\n', ...
        snrDb, tx.Nfft, tx.Ncp, tx.modName, tx.cfo);
end
estInfo = sprintf(['Estimated: estSNR=%.2f dB, estNfft=%d, estNcp=%d, estMod=%s, cfoAbs=%.4f\n' ...
                   'Burst: left=%d, right=%d, width=%d | jointScore=%.4f, cpMetric=%.4f, tfMetric=%.4f\n' ...
                   'Scheduling abstraction: MCS=%d, PRB=%d, OFDM symbols=%d\n' ...
                   'Note: true parameters are shown only for presentation/evaluation, not used as classifier input.'], ...
    localEstimateSnrForFigure(x, left, right), est.Nfft, est.Ncp, est.modName, abs(est.cfo), ...
    left, right, est.burstWidth, est.score, est.cpMetric, est.tfMetric, ...
    tx.mcs, tx.numPrb, tx.numOFDMSymbols);
text(0.02, 0.82, [trueInfo estInfo], 'FontName','Monospaced', 'FontSize', 11, 'VerticalAlignment','top');

exportgraphics(fig, outPath, 'Resolution', 220);
close(fig);
end

function estSnr = localEstimateSnrForFigure(x, left, right)
N = numel(x);
xb = x(left:right);
mask = true(N,1);
pad = 64;
mask(max(1,left-pad):min(N,right+pad)) = false;
noise = x(mask);
if numel(noise) < 16
    noisePow = median(abs(x).^2) + 1e-12;
else
    noisePow = median(abs(noise).^2) + 1e-12;
end
sigPow = mean(abs(xb).^2) + 1e-12;
estSnr = 10*log10(max(sigPow - noisePow, 1e-12) / noisePow);
end

function bytes = hexToBytes(hexStr)
hexStr = regexprep(char(hexStr), '\s+', '');
if mod(numel(hexStr), 2) ~= 0
    error('Hex string length must be even.');
end
n = numel(hexStr) / 2;
bytes = zeros(1, n, 'uint8');
for i = 1:n
    bytes(i) = uint8(hex2dec(hexStr(2*i-1:2*i)));
end
end

function hexStr = bytesToHex(bytes)
bytes = uint8(bytes(:).');
hexCell = arrayfun(@(x) sprintf('%02X', x), bytes, 'UniformOutput', false);
hexStr = strjoin(hexCell, '');
end

function h = sha256Bytes(bytes)
bytes = uint8(bytes(:).');
try
    md = java.security.MessageDigest.getInstance('SHA-256');
    md.update(int8(bytes));
    out = md.digest();
    h = typecast(int8(out), 'uint8');
    h = h(:).';
catch
    state = seedFromBytes(bytes);
    h = zeros(1, 32, 'uint8');
    for i = 1:32
        state = xorshift32(state);
        h(i) = uint8(bitand(state, uint32(255)));
    end
end
end

function state = seedFromBytes(bytes)
bytes = uint8(bytes(:));
state = uint32(2166136261);
for i = 1:numel(bytes)
    state = bitxor(state, uint32(bytes(i)));
    state = uint32(mod(uint64(state) * uint64(16777619), 2^32));
end
if state == 0
    state = uint32(2463534242);
end
end

function state = xorshift32(state)
state = bitxor(state, bitshift(state, 13));
state = bitxor(state, bitshift(state, -17));
state = bitxor(state, bitshift(state, 5));
if state == 0
    state = uint32(2463534242);
end
end

function tx = synthesizeFlowFromPayload5GLike(payload, cfg, snrDb, modality, sampleId)

payloadBytes = uint8(payload.data(:));
byteLen = numel(payloadBytes);

payloadBits = reshape(de2bi(payloadBytes, 8, 'left-msb').', [], 1);

if cfg.ul.addMacLengthHeader
    lenBits = de2bi(byteLen, 24, 'left-msb').';
    bits = [lenBits(:); payloadBits(:)];
else
    bits = payloadBits(:);
end

if cfg.ul.enableBitScrambling
    bits = scrambleBits5GLike(bits, uint32(sampleId + cfg.ul.rnti + 65537 * cfg.ul.cellId));
end

totalBits = numel(bits);
pos = 1;

if cfg.flow.sameNumerologyWithinFlow
    NfftFlow = cfg.fftCandidates(randi(numel(cfg.fftCandidates)));
    NcpFlow = cfg.cpCandidates(randi(numel(cfg.cpCandidates)));
else
    NfftFlow = NaN;
    NcpFlow = NaN;
end

waveCore = [];
burstStartList = [];
burstEndList = [];
burstMcsList = [];
burstPrbList = [];
burstActiveList = [];
burstOFDMSymList = [];
burstBitUsedList = [];

flowGuard = cfg.flow.flowGuardZeros;
waveCore = [waveCore; zeros(flowGuard + randi([0 120]), 1)];

burstIdx = 0;

while pos <= totalBits && burstIdx < cfg.flow.maxBursts
    burstIdx = burstIdx + 1;

    if cfg.flow.sameNumerologyWithinFlow
        Nfft = NfftFlow;
        Ncp = NcpFlow;
    else
        Nfft = cfg.fftCandidates(randi(numel(cfg.fftCandidates)));
        Ncp = cfg.cpCandidates(randi(numel(cfg.cpCandidates)));
    end

    mcs = cfg.ul.mcsSet(randi(numel(cfg.ul.mcsSet)));
    modName = mcsToModName(mcs);
    if ~ismember(modName, cfg.modCandidates)
        modName = cfg.modCandidates{randi(numel(cfg.modCandidates))};
    end

    M = modOrder(modName);
    bps = log2(M);

    numOFDMSymbols = randi(cfg.ul.numOFDMSymbolsRange);

    maxPrbByNfft = max(1, floor((cfg.ul.activeScRatioMax * Nfft) / 12));
    prbMin = max(1, min(cfg.ul.prbRange(1), maxPrbByNfft));
    prbMax = max(prbMin, min(cfg.ul.prbRange(2), maxPrbByNfft));
    numPrb = randi([prbMin prbMax]);

    numActive = min(numPrb * 12, floor(cfg.ul.activeScRatioMax * Nfft));
    numActive = max(bps, floor(numActive / 2) * 2);

    scIdx = activeSubcarrierIndices(Nfft, numActive);

    capacityBits = numel(scIdx) * numOFDMSymbols * bps;
    endPos = min(totalBits, pos + capacityBits - 1);
    blockBits = bits(pos:endPos);
    usedBits = numel(blockBits);

    if usedBits < capacityBits
        bitsPad = [blockBits(:); zeros(capacityBits - usedBits, 1)];
    else
        bitsPad = blockBits(:);
    end

    symbols = mapper(bitsPad, modName);
    gridData = reshape(symbols, numel(scIdx), numOFDMSymbols);

    oneBurst = [];
    for k = 1:numOFDMSymbols
        X = zeros(Nfft, 1);
        X(scIdx) = gridData(:, k);
        x = ifft(ifftshift(X), Nfft);
        xcp = [x(end-Ncp+1:end); x];
        oneBurst = [oneBurst; xcp];
    end

    if burstIdx > 1
        gapLen = randi(cfg.flow.gapZerosRange);
        waveCore = [waveCore; zeros(gapLen, 1)];
    end

    burstStart = numel(waveCore) + 1;
    waveCore = [waveCore; oneBurst];
    burstEnd = numel(waveCore);

    burstStartList(end+1,1) = burstStart;
    burstEndList(end+1,1) = burstEnd;
    burstMcsList(end+1,1) = mcs;
    burstPrbList(end+1,1) = numPrb;
    burstActiveList(end+1,1) = numActive;
    burstOFDMSymList(end+1,1) = numOFDMSymbols;
    burstBitUsedList(end+1,1) = usedBits;

    pos = endPos + 1;
end

if isempty(burstStartList)

    burstStartList = numel(waveCore) + 1;
    burstEndList = burstStartList;
    burstMcsList = cfg.ul.mcsSet(1);
    burstPrbList = cfg.ul.prbRange(1);
    burstActiveList = min(cfg.ul.prbRange(1) * 12, floor(cfg.ul.activeScRatioMax * NfftFlow));
    burstOFDMSymList = cfg.ul.numOFDMSymbolsRange(1);
    burstBitUsedList = 0;
    waveCore = [waveCore; complex(zeros(128, 1))];
end

waveCore = [waveCore; zeros(flowGuard + randi([0 120]), 1)];

waveCore = waveCore / sqrt(mean(abs(waveCore).^2) + eps);

startIndex = burstStartList(1);

if cfg.flow.sameNumerologyWithinFlow
    NfftRef = NfftFlow;
    NcpRef = NcpFlow;
else
    NfftRef = cfg.fftCandidates(randi(numel(cfg.fftCandidates)));
    NcpRef = cfg.cpCandidates(randi(numel(cfg.cpCandidates)));
end

[waveCh, chanMeta] = applyRandomChannelAndImpairments(waveCore, cfg, NfftRef, snrDb);
waveCh = addBackgroundInterference(waveCh, cfg, NfftRef, NcpRef);
rxFull = addAwgnToTargetSNR(waveCh, snrDb);

flowActiveLen = max(1, max(burstEndList) - min(burstStartList) + 1);
[rx, captureMeta] = applyRandomPartialCapture(rxFull, cfg, startIndex, flowActiveLen);

startIndexCaptured = startIndex - captureMeta.left + 1;
startIndexCaptured = max(1, startIndexCaptured);

tx.modality = modality;
tx.payloadType = payload.type;
tx.payloadBytes = payloadBytes;
tx.sourceFileName = payload.sourceFileName;
tx.sourceFilePath = payload.sourceFilePath;
tx.sourceSubtype = payload.subtype;

tx.Nfft = NfftRef;
tx.Ncp = NcpRef;
tx.modName = 'FLOW';
tx.mcs = round(mean(burstMcsList));
tx.numPrb = round(mean(burstPrbList));
tx.numActive = round(mean(burstActiveList));
tx.bits = bits;
tx.bitsPad = [];
tx.byteLen = byteLen;
tx.numOFDMSymbols = sum(burstOFDMSymList);
tx.scIdx = [];
tx.gridData = [];

tx.txWaveform = waveCore;
tx.rxWaveformFull = rxFull;
tx.rxWaveform = rx;
tx.startIndex = startIndexCaptured;
tx.cfo = chanMeta.cfo;
tx.phase = chanMeta.phase;
tx.channel = chanMeta.h;
tx.snr = snrDb;
tx.captureLeft = captureMeta.left;
tx.captureRight = captureMeta.right;

tx.flowNumBursts = numel(burstStartList);
tx.flowBurstStartList = burstStartList;
tx.flowBurstEndList = burstEndList;
tx.flowPayloadBitsUsed = sum(burstBitUsedList);
tx.flowPayloadBitsTotal = totalBits;
tx.flowCoverageRatio = min(1, tx.flowPayloadBitsUsed / max(totalBits, 1));
end

function ff = blindFlowBurstFeatures(rx, cfg)

x = rx(:);
L = numel(x);

if L < 16
    ff = emptyFlowFeatureStruct();
    return;
end

p = abs(x).^2;
env = movmean(p, 64);

medv = median(env);
madv = mad(env, 1) + 1e-12;

thr = medv + 2.0 * madv;
active = env > thr;

active = conv(double(active), ones(17,1), 'same') > 0;
active = conv(double(active), ones(9,1), 'same') >= 4;

d = diff([0; active(:); 0]);
starts = find(d == 1);
ends = find(d == -1) - 1;

if isempty(starts)
    ff = emptyFlowFeatureStruct();
    return;
end

widths = ends - starts + 1;

minWidth = max(16, round(0.002 * L));
keep = widths >= minWidth;
starts = starts(keep);
ends = ends(keep);
widths = widths(keep);

if isempty(starts)
    ff = emptyFlowFeatureStruct();
    return;
end

numBursts = numel(starts);
totalActive = sum(widths);
dutyCycle = totalActive / max(L, 1);

energies = zeros(numBursts, 1);
for i = 1:numBursts
    seg = x(starts(i):ends(i));
    energies(i) = mean(abs(seg).^2);
end

if numBursts >= 2
    gaps = starts(2:end) - ends(1:end-1) - 1;
else
    gaps = 0;
end

energyMean = mean(energies);
energyStd = std(energies);
if energyStd <= 1e-12
    energySkew = 0;
else
    energySkew = mean(((energies - energyMean) ./ energyStd).^3);
end

e = env(:);
e = e - min(e);
e = e ./ (sum(e) + eps);
envEntropy = -sum(e .* log2(e + eps)) / log2(numel(e));

ff.flowNumBurstsEst = numBursts;
ff.flowDutyCycle = dutyCycle;
ff.flowTotalActiveWidth = totalActive;
ff.flowMeanBurstWidth = mean(widths);
ff.flowStdBurstWidth = std(widths);
ff.flowMaxBurstWidth = max(widths);
ff.flowMeanGap = mean(gaps);
ff.flowStdGap = std(gaps);
ff.flowBurstEnergyMean = energyMean;
ff.flowBurstEnergyStd = energyStd;
ff.flowBurstEnergySkewness = energySkew;
ff.flowBurstRateProxy = numBursts / max(L, 1);
ff.flowEnvelopeEntropy = envEntropy;

widthsD = double(widths(:));

gapsD = double(gaps(:));

energiesD = double(energies(:));

ff.flowBurstWidthQ25 = localQuantileScalar(widthsD, 0.25);

ff.flowBurstWidthQ50 = localQuantileScalar(widthsD, 0.50);

ff.flowBurstWidthQ75 = localQuantileScalar(widthsD, 0.75);

ff.flowBurstWidthQ90 = localQuantileScalar(widthsD, 0.90);

ff.flowGapQ25 = localQuantileScalar(gapsD, 0.25);

ff.flowGapQ50 = localQuantileScalar(gapsD, 0.50);

ff.flowGapQ75 = localQuantileScalar(gapsD, 0.75);

ff.flowGapQ90 = localQuantileScalar(gapsD, 0.90);

ff.flowEnergyQ25 = localQuantileScalar(energiesD, 0.25);

ff.flowEnergyQ50 = localQuantileScalar(energiesD, 0.50);

ff.flowEnergyQ75 = localQuantileScalar(energiesD, 0.75);

ff.flowEnergyQ90 = localQuantileScalar(energiesD, 0.90);

ff.flowWidthCv = std(widthsD) / max(mean(widthsD), eps);

ff.flowGapCv = std(gapsD) / max(mean(gapsD), eps);

ff.flowEnergyCv = std(energiesD) / max(mean(energiesD), eps);

ff.flowWidthGini = localGiniScalar(widthsD);

ff.flowGapGini = localGiniScalar(gapsD);

ff.flowEnergyGini = localGiniScalar(energiesD);

ff.flowBurstRegularity = 1 / (1 + ff.flowWidthCv + ff.flowGapCv);

ff.flowActiveEdgeRate = sum(abs(diff(double(active(:))))) / max(numel(active), 1);
end

function ff = emptyFlowFeatureStruct()
ff.flowNumBurstsEst = 0;
ff.flowDutyCycle = 0;
ff.flowTotalActiveWidth = 0;
ff.flowMeanBurstWidth = 0;
ff.flowStdBurstWidth = 0;
ff.flowMaxBurstWidth = 0;
ff.flowMeanGap = 0;
ff.flowStdGap = 0;
ff.flowBurstEnergyMean = 0;
ff.flowBurstEnergyStd = 0;
ff.flowBurstEnergySkewness = 0;
ff.flowBurstRateProxy = 0;
ff.flowEnvelopeEntropy = 0;

ff.flowBurstWidthQ25 = 0;

ff.flowBurstWidthQ50 = 0;

ff.flowBurstWidthQ75 = 0;

ff.flowBurstWidthQ90 = 0;

ff.flowGapQ25 = 0;

ff.flowGapQ50 = 0;

ff.flowGapQ75 = 0;

ff.flowGapQ90 = 0;

ff.flowEnergyQ25 = 0;

ff.flowEnergyQ50 = 0;

ff.flowEnergyQ75 = 0;

ff.flowEnergyQ90 = 0;

ff.flowWidthCv = 0;

ff.flowGapCv = 0;

ff.flowEnergyCv = 0;

ff.flowWidthGini = 0;

ff.flowGapGini = 0;

ff.flowEnergyGini = 0;

ff.flowBurstRegularity = 0;

ff.flowActiveEdgeRate = 0;
end

function qv = localQuantileScalar(x, q)

x = double(x(:));

x = x(isfinite(x));

if isempty(x)

    qv = 0;

    return;

end

x = sort(x);

q = min(max(q, 0), 1);

idx = 1 + q * (numel(x) - 1);

lo = floor(idx);

hi = ceil(idx);

if lo == hi

    qv = x(lo);

else

    w = idx - lo;

    qv = (1 - w) * x(lo) + w * x(hi);

end

end

function g = localGiniScalar(x)

x = double(x(:));

x = x(isfinite(x));

x = x(x >= 0);

if isempty(x) || sum(x) <= eps

    g = 0;

    return;

end

x = sort(x);

n = numel(x);

g = (2 * sum((1:n)' .* x)) / (n * sum(x)) - (n + 1) / n;

g = max(0, min(1, g));

end

function streamBytes = appEncStreamBlockBytes(keyBytes, nonceBytes, counter, outLen)

    if nargin < 4
        outLen = 64;
    end

    keyBytes = uint8(keyBytes(:));
    nonceBytes = uint8(nonceBytes(:));
    counterBytes = appEncUint32ToBytes(counter);

    seedInput = [keyBytes; nonceBytes; counterBytes];
    seed = appEncFnv1a32(seedInput);

    if seed == uint32(0)
        seed = uint32(2463534242);
    end

    streamBytes = zeros(outLen, 1, 'uint8');
    state = seed;
    pos = 1;

    while pos <= outLen
        state = appEncXorshift32(state);
        block = appEncUint32ToBytes(state);

        takeN = min(4, outLen - pos + 1);
        streamBytes(pos:pos+takeN-1) = block(1:takeN);

        pos = pos + takeN;
    end
end

function digestBytes = appEncSha256Bytes(inputBytes)

    digestBytes = appEncPseudoDigestBytes(inputBytes, 32);
end

function digestBytes = appEncPseudoDigestBytes(inputBytes, outLen)

    if nargin < 2
        outLen = 32;
    end

    inputBytes = uint8(inputBytes(:));
    seed = appEncFnv1a32(inputBytes);

    if seed == uint32(0)
        seed = uint32(2166136261);
    end

    digestBytes = zeros(outLen, 1, 'uint8');
    state = seed;
    pos = 1;

    while pos <= outLen
        state = appEncXorshift32(state);
        block = appEncUint32ToBytes(state);

        takeN = min(4, outLen - pos + 1);
        digestBytes(pos:pos+takeN-1) = block(1:takeN);

        pos = pos + takeN;
    end
end

function h = appEncFnv1a32(bytes)

    bytes = uint8(bytes(:));

    hDouble = 2166136261;
    prime = 16777619;
    mod32 = 4294967296;

    for i = 1:numel(bytes)
        hUint = uint32(mod(hDouble, mod32));
        hUint = bitxor(hUint, uint32(bytes(i)));
        hDouble = mod(double(hUint) * prime, mod32);
    end

    h = uint32(mod(hDouble, mod32));

    if h == uint32(0)
        h = uint32(2166136261);
    end
end

function x = appEncXorshift32(x)

    x = uint32(x);

    if x == uint32(0)
        x = uint32(2463534242);
    end

    x = bitxor(x, bitshift(x, 13));
    x = bitxor(x, bitshift(x, -17));
    x = bitxor(x, bitshift(x, 5));

    if x == uint32(0)
        x = uint32(2463534242);
    end
end

function b = appEncUint32ToBytes(x)

    x = uint32(x);
    b = typecast(x, 'uint8');
    b = uint8(b(:));
end

function checkNRToolboxAvailability(cfg)
if ~isfield(cfg, 'nrPhy') || ~cfg.nrPhy.enable
    return;
end

requiredFns = { ...
    'nrCarrierConfig', 'nrPUSCHConfig', 'nrPUSCH', 'nrPUSCHIndices', ...
    'nrPUSCHDMRS', 'nrPUSCHDMRSIndices', 'nrResourceGrid', ...
    'nrOFDMModulate', 'nrOFDMDemodulate', 'nrTDLChannel', 'nrChannelEstimate' ...
};

missing = {};
for i = 1:numel(requiredFns)
    if exist(requiredFns{i}, 'file') ~= 2 && exist(requiredFns{i}, 'class') ~= 8
        missing{end+1} = requiredFns{i};
    end
end

if ~isempty(missing)
    msg = sprintf('NR Toolbox PHY requested, but missing required 5G Toolbox functions/classes: %s', strjoin(missing, ', '));
    if isfield(cfg.nrPhy, 'require5GToolbox') && cfg.nrPhy.require5GToolbox
        error('%s', msg);
    else
        warning('%s', msg);
    end
end
end

function [payloadOut, meta] = maybeApplyRrcMacNrLikeAbstraction(payloadIn, cfg, secMeta, sampleId, snrDb)

payloadOut = payloadIn;
meta = initRrcMacNrMeta();

if isfield(cfg, 'rrcLike') && cfg.rrcLike.enable
    meta.rrcLikeEnabled = true;
    meta.rrcState = string(cfg.rrcLike.state);
    meta.rrcSecurityMode = string(cfg.rrcLike.securityMode);
    meta.rrcSrbId = double(cfg.rrcLike.srbId);
    meta.rrcDrbId = double(cfg.rrcLike.drbId);
    meta.rrcPduSessionId = double(cfg.rrcLike.pduSessionId);
    meta.rrcQfi = double(cfg.rrcLike.qfi);
    meta.rrcMeasurementConfig = string(cfg.rrcLike.measurementConfig);
else
    meta.rrcLikeEnabled = false;
end

if isfield(cfg, 'macLike') && cfg.macLike.enable
    meta.macLikeEnabled = true;
    meta.macLcid = double(cfg.macLike.lcid);

    harqLo = cfg.macLike.harqProcessRange(1);
    harqHi = cfg.macLike.harqProcessRange(2);
    meta.macHarqProcessId = double(harqLo + mod(round(sampleId)-1, harqHi-harqLo+1));

    payloadBytes = uint8(payloadIn.data(:));
    bsrBucket = computeBsrBucket(numel(payloadBytes), cfg.macLike.bsrBucketBytes);
    meta.macBsrBucket = double(bsrBucket);

    if cfg.macLike.addSubheader
        hdr = buildMacLikeSubheader(payloadBytes, cfg, meta, sampleId);
        payloadOut.data = uint8([hdr(:); payloadBytes(:)].');
        meta.macSubheaderBytes = numel(hdr);
        meta.macPduBytes = numel(payloadOut.data);
    else
        meta.macSubheaderBytes = 0;
        meta.macPduBytes = numel(payloadBytes);
    end
else
    payloadBytes = uint8(payloadIn.data(:));
    meta.macLikeEnabled = false;
    meta.macPduBytes = numel(payloadBytes);
end

payloadOut.rrcMacMeta = meta;
end

function meta = initRrcMacNrMeta()
meta = struct();
meta.rrcLikeEnabled = false;
meta.rrcState = "none";
meta.rrcSecurityMode = "none";
meta.rrcSrbId = 0;
meta.rrcDrbId = 0;
meta.rrcPduSessionId = 0;
meta.rrcQfi = 0;
meta.rrcMeasurementConfig = "none";

meta.macLikeEnabled = false;
meta.macLcid = 0;
meta.macHarqProcessId = 0;
meta.macBsrBucket = 0;
meta.macSubheaderBytes = 0;
meta.macPduBytes = 0;
end

function bucket = computeBsrBucket(nBytes, bucketEdges)
bucketEdges = double(bucketEdges(:));
bucket = find(nBytes <= bucketEdges, 1, 'first') - 1;
if isempty(bucket) || bucket < 0
    bucket = numel(bucketEdges) - 1;
end
bucket = min(max(bucket, 0), 255);
end

function hdr = buildMacLikeSubheader(payloadBytes, cfg, meta, sampleId)

hdr = uint8([ ...
    bitand(uint8(meta.macLcid), uint8(63)); ...
    bitand(uint8(meta.macHarqProcessId), uint8(31)); ...
    bitand(uint8(meta.macBsrBucket), uint8(255)); ...
    uint8(mod(cfg.ul.rnti + sampleId, 256)) ...
]);

if isfield(cfg.macLike, 'includePayloadLength') && cfg.macLike.includePayloadLength
    L = numel(payloadBytes);
    hdr = [hdr; uint8(bitand(bitshift(uint32(L), -8), 255)); uint8(bitand(uint32(L), 255))];
end
end

function tx = synthesizePacketFromPayloadNRToolbox(payload, cfg, snrDb, modality, sampleId)

mcs = cfg.ul.mcsSet(randi(numel(cfg.ul.mcsSet)));
modName = mcsToModName(mcs);
if ~ismember(modName, cfg.modCandidates)
    modName = cfg.modCandidates{randi(numel(cfg.modCandidates))};
end

payloadBytes = uint8(payload.data(:));
byteLen = numel(payloadBytes);
payloadBits = reshape(de2bi(payloadBytes, 8, 'left-msb').', [], 1);

if cfg.ul.enableBitScrambling
    payloadBits = scrambleBits5GLike(payloadBits, uint32(sampleId + cfg.ul.rnti + 65537 * cfg.ul.cellId));
end

numPrb = chooseNrPrbCount(cfg);
numOFDMSymbols = cfg.nrPhy.symbolAllocation(2);

[burstWave, nrMeta] = buildNRPUSCHBurstWaveform(payloadBits, cfg, modName, numPrb, sampleId, 0);

pre = zeros(cfg.guardZeros + randi([0 120]), 1);
post = zeros(cfg.guardZeros + randi([0 120]), 1);
wave = [pre; burstWave; post];
startIndex = numel(pre) + 1;

[rxFull, chanMeta] = applyNRChannelAndImpairments(wave, cfg, nrMeta.ofdmInfo.Nfft, round(mean(nrMeta.ofdmInfo.CyclicPrefixLengths)), snrDb);
[rx, captureMeta] = applyRandomPartialCapture(rxFull, cfg, startIndex, numel(burstWave));

startIndexCaptured = startIndex - captureMeta.left + 1;
startIndexCaptured = max(1, startIndexCaptured);

tx = fillNRCompatibleTxStruct(payload, modality, payloadBytes, payloadBits, byteLen, ...
    nrMeta, modName, mcs, numPrb, numOFDMSymbols, wave, rxFull, rx, ...
    startIndexCaptured, captureMeta, chanMeta, sampleId);
tx.nrFirstBurstStartFull = startIndex;
tx.nrFirstBurstLength = numel(burstWave);

tx.flowNumBursts = 1;
tx.flowPayloadBitsUsed = numel(payloadBits);
tx.flowPayloadBitsTotal = numel(payloadBits);
tx.flowCoverageRatio = 1;
end

function tx = synthesizeFlowFromPayloadNRToolbox(payload, cfg, snrDb, modality, sampleId)

payloadBytes = uint8(payload.data(:));
byteLen = numel(payloadBytes);
bits = reshape(de2bi(payloadBytes, 8, 'left-msb').', [], 1);

if cfg.ul.enableBitScrambling
    bits = scrambleBits5GLike(bits, uint32(sampleId + cfg.ul.rnti + 65537 * cfg.ul.cellId));
end

totalBits = numel(bits);
pos = 1;

waveCore = [];
burstStartList = [];
burstEndList = [];
burstMcsList = [];
burstPrbList = [];
burstActiveList = [];
burstOFDMSymList = [];
burstBitUsedList = [];
firstNrMeta = [];
lastNrMeta = [];
firstModName = '16QAM';
firstMcs = cfg.ul.mcsSet(1);
firstNumPrb = cfg.nrPhy.nSizeGrid;

flowGuard = cfg.flow.flowGuardZeros;
waveCore = [waveCore; zeros(flowGuard + randi([0 120]), 1)];

burstIdx = 0;

while pos <= totalBits && burstIdx < cfg.flow.maxBursts
    burstIdx = burstIdx + 1;

    mcs = cfg.ul.mcsSet(randi(numel(cfg.ul.mcsSet)));
    modName = mcsToModName(mcs);
    if ~ismember(modName, cfg.modCandidates)
        modName = cfg.modCandidates{randi(numel(cfg.modCandidates))};
    end

    numPrb = chooseNrPrbCount(cfg);

    bps = localNRBitsPerSymbol(modName);
    conservativeBits = min(totalBits - pos + 1, max(1, numPrb * 12 * cfg.nrPhy.symbolAllocation(2) * bps));
    blockBits = bits(pos:min(totalBits, pos + conservativeBits - 1));

    [oneBurst, nrMeta] = buildNRPUSCHBurstWaveform(blockBits, cfg, modName, numPrb, sampleId, burstIdx-1);

    usedBits = min(numel(blockBits), nrMeta.G);
    pos = pos + usedBits;

    if burstIdx > 1
        gapLen = randi(cfg.flow.gapZerosRange);
        waveCore = [waveCore; zeros(gapLen, 1)];
    end

    burstStart = numel(waveCore) + 1;
    waveCore = [waveCore; oneBurst];
    burstEnd = numel(waveCore);

    burstStartList(end+1,1) = burstStart;
    burstEndList(end+1,1) = burstEnd;
    burstMcsList(end+1,1) = mcs;
    burstPrbList(end+1,1) = numPrb;
    burstActiveList(end+1,1) = numPrb * 12;
    burstOFDMSymList(end+1,1) = cfg.nrPhy.symbolAllocation(2);
    burstBitUsedList(end+1,1) = usedBits;

    if burstIdx == 1
        firstNrMeta = nrMeta;
        firstModName = modName;
        firstMcs = mcs;
        firstNumPrb = numPrb;
    end
    lastNrMeta = nrMeta;
end

if isempty(burstStartList)
    [oneBurst, firstNrMeta] = buildNRPUSCHBurstWaveform(zeros(16,1), cfg, 'QPSK', chooseNrPrbCount(cfg), sampleId, 0);
    lastNrMeta = firstNrMeta;
    waveCore = [waveCore; oneBurst];
    burstStartList = flowGuard + 1;
    burstEndList = numel(waveCore);
    burstMcsList = cfg.ul.mcsSet(1);
    burstPrbList = chooseNrPrbCount(cfg);
    burstActiveList = burstPrbList * 12;
    burstOFDMSymList = cfg.nrPhy.symbolAllocation(2);
    burstBitUsedList = 0;
end

waveCore = [waveCore; zeros(flowGuard + randi([0 120]), 1)];

waveCore = waveCore / sqrt(mean(abs(waveCore).^2) + eps);

startIndex = burstStartList(1);
NfftRef = firstNrMeta.ofdmInfo.Nfft;
NcpRef = round(mean(firstNrMeta.ofdmInfo.CyclicPrefixLengths));

[rxFull, chanMeta] = applyNRChannelAndImpairments(waveCore, cfg, NfftRef, NcpRef, snrDb);

flowActiveLen = max(1, max(burstEndList) - min(burstStartList) + 1);
[rx, captureMeta] = applyRandomPartialCapture(rxFull, cfg, startIndex, flowActiveLen);

startIndexCaptured = startIndex - captureMeta.left + 1;
startIndexCaptured = max(1, startIndexCaptured);

tx = fillNRCompatibleTxStruct(payload, modality, payloadBytes, bits, byteLen, ...
    firstNrMeta, 'NRFLOW', round(mean(burstMcsList)), round(mean(burstPrbList)), ...
    sum(burstOFDMSymList), waveCore, rxFull, rx, startIndexCaptured, captureMeta, chanMeta, sampleId);
tx.nrFirstBurstStartFull = startIndex;
tx.nrFirstBurstLength = max(1, burstEndList(1) - burstStartList(1) + 1);

tx.nrMetaLast = lastNrMeta;
tx.mcs = round(mean(burstMcsList));
tx.numPrb = round(mean(burstPrbList));
tx.numActive = round(mean(burstActiveList));
tx.numOFDMSymbols = sum(burstOFDMSymList);

tx.flowNumBursts = numel(burstStartList);
tx.flowBurstStartList = burstStartList;
tx.flowBurstEndList = burstEndList;
tx.flowPayloadBitsUsed = sum(burstBitUsedList);
tx.flowPayloadBitsTotal = totalBits;
tx.flowCoverageRatio = min(1, tx.flowPayloadBitsUsed / max(totalBits, 1));
tx.flowBurstMcsList = burstMcsList;
tx.flowBurstPrbList = burstPrbList;
end

function numPrb = chooseNrPrbCount(cfg)
prbMin = max(1, min(cfg.ul.prbRange(1), cfg.nrPhy.nSizeGrid));
prbMax = max(prbMin, min(cfg.ul.prbRange(2), cfg.nrPhy.nSizeGrid));
numPrb = randi([prbMin prbMax]);
end

function [waveform, meta] = buildNRPUSCHBurstWaveform(inputBits, cfg, modName, numPrb, sampleId, slotOffset)

carrier = nrCarrierConfig;
carrier.NCellID = mod(cfg.nrPhy.nCellID + sampleId, 1008);
carrier.SubcarrierSpacing = cfg.nrPhy.subcarrierSpacing;
carrier.CyclicPrefix = cfg.nrPhy.cyclicPrefix;
carrier.NSizeGrid = cfg.nrPhy.nSizeGrid;
carrier.NStartGrid = cfg.nrPhy.nStartGrid;
carrier.NSlot = mod(slotOffset, 10);
carrier.NFrame = floor(slotOffset / 10);

pusch = nrPUSCHConfig;
pusch.NSizeBWP = carrier.NSizeGrid;
pusch.NStartBWP = cfg.nrPhy.nStartBWP;
pusch.Modulation = modName;
pusch.NumLayers = cfg.nrPhy.numLayers;
pusch.PRBSet = 0:(numPrb-1);
pusch.SymbolAllocation = cfg.nrPhy.symbolAllocation;
pusch.MappingType = cfg.nrPhy.mappingType;
pusch.NID = carrier.NCellID;
pusch.RNTI = cfg.nrPhy.rnti + mod(sampleId, 50000);
pusch.TransformPrecoding = cfg.nrPhy.transformPrecoding;

try
    pusch.DMRS.DMRSConfigurationType = cfg.nrPhy.dmrsConfigurationType;
    pusch.DMRS.DMRSTypeAPosition = cfg.nrPhy.dmrsTypeAPosition;
    pusch.DMRS.DMRSLength = cfg.nrPhy.dmrsLength;
    pusch.DMRS.DMRSAdditionalPosition = cfg.nrPhy.dmrsAdditionalPosition;
catch

end

puschInd = nrPUSCHIndices(carrier, pusch);
bitsPerSym = localNRBitsPerSymbol(modName);
G = numel(puschInd) * bitsPerSym * pusch.NumLayers;

inputBits = double(inputBits(:) ~= 0);
if numel(inputBits) < G
    padBits = zeros(G - numel(inputBits), 1);
    cw = [inputBits; padBits];
else
    cw = inputBits(1:G);
end

puschSym = nrPUSCH(carrier, pusch, cw);

grid = nrResourceGrid(carrier, pusch.NumLayers);
grid(puschInd) = puschSym;

dmrsInd = [];
dmrsSym = [];
try
    dmrsInd = nrPUSCHDMRSIndices(carrier, pusch);
    dmrsSym = nrPUSCHDMRS(carrier, pusch);
    grid(dmrsInd) = dmrsSym;
catch

end

[waveform, ofdmInfo] = nrOFDMModulate(carrier, grid);

meta = struct();
meta.carrier = carrier;
meta.pusch = pusch;
meta.puschInd = puschInd;
meta.dmrsInd = dmrsInd;
meta.dmrsSym = dmrsSym;
meta.grid = grid;
meta.ofdmInfo = ofdmInfo;
meta.modName = string(modName);
meta.numPrb = numPrb;
meta.G = G;
meta.numActiveSubcarriers = numPrb * 12;
meta.waveformLength = numel(waveform);
meta.hasDMRS = ~isempty(dmrsInd);
end

function [rxFull, chanMeta] = applyNRChannelAndImpairments(waveCore, cfg, NfftRef, NcpRef, snrDb)

x = waveCore(:);

tdl = nrTDLChannel;
tdl.DelayProfile = cfg.nrPhy.delayProfile;
tdl.DelaySpread = cfg.nrPhy.delaySpread;
tdl.MaximumDopplerShift = cfg.nrPhy.maximumDopplerShift;
tdl.NumTransmitAntennas = cfg.nrPhy.numTransmitAntennas;
tdl.NumReceiveAntennas = cfg.nrPhy.numReceiveAntennas;
tdl.TransmissionDirection = 'Uplink';
tdl.RandomStream = 'mt19937ar with seed';
tdl.Seed = 300000 + round(1000 * rand);
tdl.NormalizePathGains = true;
tdl.NormalizeChannelOutputs = true;

tdl.SampleRate = cfg.nrPhy.subcarrierSpacing * 1e3 * max(NfftRef, 1);

chInfo = info(tdl);
maxChDelay = 0;
if isfield(chInfo, 'MaximumChannelDelay')
    maxChDelay = chInfo.MaximumChannelDelay;
end

xPad = [x; zeros(maxChDelay + 10, 1)];
try
    [y, pathGains, sampleTimes] = tdl(xPad);
catch
    y = tdl(xPad);
    pathGains = [];
    sampleTimes = [];
end
y = y(:,1);

if isfield(cfg.nrPhy, 'rxGainDb') && ~isempty(cfg.nrPhy.rxGainDb)
    y = y * 10^(cfg.nrPhy.rxGainDb/20);
end

if isfield(cfg.nrPhy, 'applyLegacyRfImpairments') && cfg.nrPhy.applyLegacyRfImpairments
    [y, rfMeta] = applyLegacyRFImpairmentsOnly(y, cfg, NfftRef);
else
    rfMeta = struct('cfo', 0, 'phase', 0, 'h', 1);
end

if isfield(cfg.nrPhy, 'addBackgroundInterference') && cfg.nrPhy.addBackgroundInterference
    y = addBackgroundInterference(y, cfg, NfftRef, NcpRef);
end

rxFull = addAwgnToTargetSNR(y, snrDb);

chanMeta = struct();
chanMeta.cfo = rfMeta.cfo;
chanMeta.phase = rfMeta.phase;
chanMeta.h = rfMeta.h;
chanMeta.pathGains = pathGains;
chanMeta.sampleTimes = sampleTimes;
chanMeta.delayProfile = string(cfg.nrPhy.delayProfile);
chanMeta.delaySpread = cfg.nrPhy.delaySpread;
chanMeta.maximumDopplerShift = cfg.nrPhy.maximumDopplerShift;
chanMeta.maxChannelDelay = maxChDelay;
chanMeta.NfftRef = NfftRef;
chanMeta.NcpRef = NcpRef;
end

function [y, meta] = applyLegacyRFImpairmentsOnly(x, cfg, Nfft)
x = x(:);
n = (0:numel(x)-1).';

cfo = cfg.channel.cfoNormRange(1) + rand * diff(cfg.channel.cfoNormRange);
phase = (2*rand - 1) * cfg.channel.phaseRange;
y = x .* exp(1j * (2*pi*cfo*n/max(Nfft,1) + phase));

igDb = cfg.channel.iqGainImbalanceDbRange(1) + rand * diff(cfg.channel.iqGainImbalanceDbRange);
ipDeg = cfg.channel.iqPhaseImbalanceDegRange(1) + rand * diff(cfg.channel.iqPhaseImbalanceDegRange);
g = 10^(igDb/20);
phi = ipDeg*pi/180;
I = real(y) * g;
Q = imag(y) / max(g, eps);
y = I + 1j * (Q*cos(phi) + I*sin(phi));

pnStd = cfg.channel.phaseNoiseStdRange(1) + rand * diff(cfg.channel.phaseNoiseStdRange);
if pnStd > 0
    pn = cumsum(pnStd * randn(size(y)));
    y = y .* exp(1j * pn);
end

p = mean(abs(y).^2) + eps;
dcDb = cfg.channel.dcOffsetPowerDbRange(1) + rand * diff(cfg.channel.dcOffsetPowerDbRange);
dcAmp = sqrt(p * 10^(dcDb/10));
y = y + dcAmp * exp(1j*2*pi*rand);

if cfg.channel.enablePaNonlinearity
    backoff = cfg.channel.paBackoffDbRange(1) + rand * diff(cfg.channel.paBackoffDbRange);
    A = sqrt(mean(abs(y).^2) + eps) * 10^(backoff/20);
    pRapp = cfg.channel.paRappP;
    r = abs(y);
    y = y ./ ((1 + (r./A).^(2*pRapp)).^(1/(2*pRapp)) + eps);
end

meta.cfo = cfo;
meta.phase = phase;
meta.h = 1;
end

function tx = fillNRCompatibleTxStruct(payload, modality, payloadBytes, bits, byteLen, nrMeta, modName, mcs, numPrb, numOFDMSymbols, wave, rxFull, rx, startIndexCaptured, captureMeta, chanMeta, sampleId)
tx = struct();
tx.modality = modality;
tx.payloadType = payload.type;
tx.payloadBytes = payloadBytes;
tx.sourceFileName = payload.sourceFileName;
tx.sourceFilePath = payload.sourceFilePath;
tx.sourceSubtype = payload.subtype;

tx.Nfft = nrMeta.ofdmInfo.Nfft;
tx.Ncp = round(mean(nrMeta.ofdmInfo.CyclicPrefixLengths));
tx.modName = modName;
tx.mcs = mcs;
tx.numPrb = numPrb;
tx.numActive = nrMeta.numActiveSubcarriers;
tx.bits = bits;
tx.bitsPad = [];
tx.byteLen = byteLen;
tx.numOFDMSymbols = numOFDMSymbols;
tx.scIdx = [];
tx.gridData = [];
tx.txWaveform = wave;
tx.rxWaveformFull = rxFull;
tx.rxWaveform = rx;
tx.startIndex = startIndexCaptured;
tx.cfo = chanMeta.cfo;
tx.phase = chanMeta.phase;
tx.channel = chanMeta.h;
tx.snr = NaN;
tx.captureLeft = captureMeta.left;
tx.captureRight = captureMeta.right;
tx.nrMeta = nrMeta;
tx.channelMeta = chanMeta;
if isfield(payload, 'rrcMacMeta')
    tx.rrcMacMeta = payload.rrcMacMeta;
else
    tx.rrcMacMeta = initRrcMacNrMeta();
end
end

function bps = localNRBitsPerSymbol(modName)
switch upper(char(modName))
    case 'PI/2-BPSK'
        bps = 1;
    case 'QPSK'
        bps = 2;
    case '16QAM'
        bps = 4;
    case '64QAM'
        bps = 6;
    case '256QAM'
        bps = 8;
    otherwise
        bps = log2(modOrder(modName));
end
end

function obs = emptyNRChannelObservability()
obs = struct();
obs.rsrpLikeFullDb = NaN;
obs.rsrpLikeBurstDb = NaN;
obs.noiseFloorLikeDb = NaN;
obs.csiLikeMeanGainDb = NaN;
obs.csiLikeGainStdDb = NaN;
obs.csiLikeFreqSelectivity = NaN;
obs.csiLikePhaseStd = NaN;
obs.csiLikeNoiseEstimate = NaN;
obs.cirLikeNumTapsTrue = NaN;
obs.cirLikeRmsDelayTrue = NaN;
obs.cirLikeMaxDelayTrue = NaN;
obs.cirLikePowerSpreadDbTrue = NaN;
obs.cirLikeNumTapsEst = NaN;
obs.cirLikeRmsDelayEst = NaN;
obs.cirLikeMaxDelayEst = NaN;
obs.nrTdlDelayProfile = "none";
obs.nrTdlDelaySpread = NaN;
obs.nrMaxDopplerShift = NaN;
end

function obs = extractNRChannelObservability(tx, est, cfg)

obs = emptyNRChannelObservability();

rx = tx.rxWaveform(:);
if isempty(rx)
    return;
end

obs.rsrpLikeFullDb = 10*log10(mean(abs(rx).^2) + eps);

left = max(1, round(est.burstLeft) - cfg.channelObs.burstPad);
right = min(numel(rx), round(est.burstRight) + cfg.channelObs.burstPad);
if right <= left
    left = 1;
    right = numel(rx);
end
xb = rx(left:right);
obs.rsrpLikeBurstDb = 10*log10(mean(abs(xb).^2) + eps);

noiseMask = true(numel(rx), 1);
noiseMask(left:right) = false;
noiseSamples = rx(noiseMask);
if numel(noiseSamples) < 16
    obs.noiseFloorLikeDb = 10*log10(median(abs(rx).^2) + eps);
else
    obs.noiseFloorLikeDb = 10*log10(median(abs(noiseSamples).^2) + eps);
end

if isfield(tx, 'channelMeta')
    obs.nrTdlDelayProfile = string(tx.channelMeta.delayProfile);
    obs.nrTdlDelaySpread = double(tx.channelMeta.delaySpread);
    obs.nrMaxDopplerShift = double(tx.channelMeta.maximumDopplerShift);

    if isfield(tx.channelMeta, 'pathGains') && ~isempty(tx.channelMeta.pathGains)
        pg = squeeze(tx.channelMeta.pathGains);
        pgPow = abs(pg(:)).^2;
        obs.cirLikeNumTapsTrue = numel(pgPow);
        obs.cirLikePowerSpreadDbTrue = 10*log10(max(pgPow) / (min(pgPow(pgPow > 0)) + eps) + eps);
        obs.cirLikeRmsDelayTrue = estimateRmsDelayFromPower(pgPow);
        obs.cirLikeMaxDelayTrue = numel(pgPow) - 1;
    end
end

try
    if isfield(tx, 'nrMeta') && isfield(tx.nrMeta, 'hasDMRS') && tx.nrMeta.hasDMRS && ~isempty(tx.nrMeta.dmrsInd)
        N = numel(tx.nrMeta.ofdmInfo.CyclicPrefixLengths) + tx.nrMeta.ofdmInfo.Nfft;
        rxForGridFull = tx.rxWaveformFull(:);
        if isfield(tx, 'nrFirstBurstStartFull') && isfield(tx.nrMeta, 'waveformLength')
            st = max(1, round(tx.nrFirstBurstStartFull));
            en = min(numel(rxForGridFull), st + round(tx.nrMeta.waveformLength) + 2*round(tx.channelMeta.maxChannelDelay) + 20 - 1);
            rxForGrid = rxForGridFull(st:en);
        else
            rxForGrid = rxForGridFull;
        end
        if numel(rxForGrid) > 0
            rxGrid = nrOFDMDemodulate(tx.nrMeta.carrier, rxForGrid);
            [hest, nVar] = nrChannelEstimate(tx.nrMeta.carrier, rxGrid, tx.nrMeta.dmrsInd, tx.nrMeta.dmrsSym);
            h = hest(:);
            h = h(isfinite(real(h)) & isfinite(imag(h)) & abs(h) > 0);
            if ~isempty(h)
                gDb = 20*log10(abs(h) + eps);
                obs.csiLikeMeanGainDb = mean(gDb);
                obs.csiLikeGainStdDb = std(gDb);
                obs.csiLikeFreqSelectivity = std(abs(h)) / (mean(abs(h)) + eps);
                obs.csiLikePhaseStd = std(unwrap(angle(h)));
                obs.csiLikeNoiseEstimate = double(nVar);

                cirEst = ifft(h, min(1024, max(64, 2^nextpow2(numel(h)))));
                p = abs(cirEst(:)).^2;
                pDb = 10*log10(p + eps);
                keep = pDb > max(pDb) + cfg.channelObs.cirPowerThresholdDb;
                obs.cirLikeNumTapsEst = sum(keep);
                obs.cirLikeRmsDelayEst = estimateRmsDelayFromPower(p);
                kk = find(keep);
                if isempty(kk)
                    obs.cirLikeMaxDelayEst = 0;
                else
                    obs.cirLikeMaxDelayEst = max(kk) - min(kk);
                end
            end
        end
    end
catch

end
end

function rmsDelay = estimateRmsDelayFromPower(p)
p = double(p(:));
p(~isfinite(p)) = 0;
p(p < 0) = 0;
if isempty(p) || sum(p) <= eps
    rmsDelay = 0;
    return;
end
idx = (0:numel(p)-1).';
prob = p / sum(p);
mu = sum(idx .* prob);
rmsDelay = sqrt(sum(((idx - mu).^2) .* prob));
end
