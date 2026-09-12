#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import random
import warnings
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Tuple

import joblib
import numpy as np
import pandas as pd
from PIL import Image

try:
    from xgboost import XGBClassifier
except Exception as exc:
    raise RuntimeError(
        "xgboost is not installed or cannot be imported. Install it first:\n"
        "  pip install xgboost\n"
        f"Original error: {exc}"
    )

from sklearn.impute import SimpleImputer
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.utils.class_weight import compute_sample_weight

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

LABEL_ORDER = ["text", "audio", "image", "video"]
LABEL_TO_ID = {name: idx for idx, name in enumerate(LABEL_ORDER)}
ID_TO_LABEL = {idx: name for name, idx in LABEL_TO_ID.items()}

FEATURE_COLS = [
    "burstMean",
    "burstStd",
    "burstSkewness",
    "burstKurtosis",
    "fftEntropy",
    "fftPeakRatio",
    "occupiedBandwidthRatio",
    "tfOccupancyRatio",
    "phyThroughputProxy",
    "estNoisePower",
    "estSnrFromBurst",
    "rxSkewness",
    "rxKurtosis",
    "rxPAPR",
    "rxRMS",
    "burstWidth",
    "jointScore",
    "estNcp",
    "estMod",
    "specFluxMean",
    "rxSpecFlatness",
    "cfoAbs",
    "flowNumBurstsEst",
    "flowDutyCycle",
    "flowTotalActiveWidth",
    "flowMeanBurstWidth",
    "flowStdBurstWidth",
    "flowMaxBurstWidth",
    "flowMeanGap",
    "flowStdGap",
    "flowBurstEnergyMean",
    "flowBurstEnergyStd",
    "flowBurstEnergySkewness",
    "flowBurstRateProxy",
    "flowEnvelopeEntropy",
    "frameEnergyVar",
    "specCentroidMean",
    "specCentroidStd",
    "flowBurstWidthQ25",
    "flowBurstWidthQ50",
    "flowBurstWidthQ75",
    "flowBurstWidthQ90",
    "flowGapQ25",
    "flowGapQ50",
    "flowGapQ75",
    "flowGapQ90",
    "flowEnergyQ25",
    "flowEnergyQ50",
    "flowEnergyQ75",
    "flowEnergyQ90",
    "flowWidthCv",
    "flowGapCv",
    "flowEnergyCv",
    "flowWidthGini",
    "flowGapGini",
    "flowEnergyGini",
    "flowBurstRegularity",
    "flowActiveEdgeRate",
]

LENGTH_ORACLE_RAW_COLS = [
    "payloadBytes",
    "payloadBytesPlain",
    "payloadBytesAfterStrip",
    "payloadBytesTx",
    "trueFlowPayloadBitsUsed",
    "trueFlowPayloadBitsTotal",
    "trueFlowCoverageRatio",
]

LENGTH_ORACLE_FEATURE_COLS = [

    "lo_payload_len_bucket",
]

CHANNEL_EST_FEATURE_COLS = [
    "rsrpLikeFullDb",
    "rsrpLikeBurstDb",
    "noiseFloorLikeDb",
    "csiLikeMeanGainDb",
    "csiLikeGainStdDb",
    "csiLikeFreqSelectivity",
    "csiLikePhaseStd",
    "csiLikeNoiseEstimate",
    "cirLikeNumTapsEst",
    "cirLikeRmsDelayEst",
    "cirLikeMaxDelayEst",
]

EST_MOD_MAP = {
    "unknown": 0,
    "qpsk": 1,
    "16qam": 2,
    "64qam": 3,
    "256qam": 4,
}

LEAKAGE_COLS = {
    "snr",
    "trueSnrDb",
    "snrBucket",
    "modality",
    "label",
    "payloadType",
    "payloadBytes",
    "sourceFileName",
    "sourceFilePath",
    "waveformImagePath",
    "spectrumImagePath",
    "annotatedWaveformPath",
    "open5gsValidated",
    "open5gsReceivedFilePath",
    "open5gsSha256",
    "encEnabled",
    "encMode",
    "payloadBytesPlain",
    "payloadBytesAfterStrip",
    "payloadBytesTx",
    "pdcpCountStart",
    "pdcpSnStart",
    "bearer",
    "direction",
    "suciLike",
    "nasMacHex",
    "rrcMacHex",
    "trueNfft",
    "trueNcp",
    "trueMod",
    "mcs",
    "numPrb",
    "numActiveSubcarriers",
    "numOFDMSymbols",
    "trueStart",
    "trueCFO",
    "fftOk",
    "cpOk",
    "modOk",
    "ser",
    "evm",

    "nrPhyEnabled",
    "rrcLikeEnabled",
    "rrcState",
    "rrcSecurityMode",
    "rrcSrbId",
    "rrcDrbId",
    "rrcPduSessionId",
    "rrcQfi",
    "rrcMeasurementConfig",
    "macLikeEnabled",
    "macLcid",
    "macHarqProcessId",
    "macBsrBucket",
    "macSubheaderBytes",
    "macPduBytes",
    "nrTdlDelayProfile",
    "nrTdlDelaySpread",
    "nrMaxDopplerShift",
    "cirLikeNumTapsTrue",
    "cirLikeNonZeroTapsTrue",
    "cirLikeRmsDelayTrue",
    "cirLikeMaxDelayTrue",
    "cirLikePowerSpreadDbTrue",
}

@dataclass
class Config:
    matlab_out: str
    out_dir: str
    seed: int = 2026

    val_ratio: float = 0.10
    test_ratio: float = 0.10
    reuse_split: bool = True

    image_size: int = 224
    batch_size: int = 64
    num_workers: int = 2

    cnn_epochs: int = 40
    cnn_lr: float = 1e-3
    cnn_weight_decay: float = 1e-4
    cnn_patience: int = 8
    cnn_loss: str = "focal"
    cnn_focal_gamma: float = 2.0
    cnn_text_weight: float = 1.0
    cnn_audio_weight: float = 2.0
    cnn_image_weight: float = 2.5
    cnn_video_weight: float = 1.2
    cnn_augment: bool = True
    cnn_select_audio_image_weight: float = 0.25

    xgb_n_estimators: int = 800
    xgb_max_depth: int = 4
    xgb_learning_rate: float = 0.025
    xgb_subsample: float = 0.85
    xgb_colsample_bytree: float = 0.85
    xgb_min_child_weight: float = 2.0
    xgb_reg_alpha: float = 0.10
    xgb_reg_lambda: float = 1.50
    xgb_early_stopping_rounds: int = 60

    alpha_step: float = 0.01

    enable_length_oracle: bool = True
    enable_channel_est_features: bool = False
    length_oracle_bins: int = 6
    length_oracle_noise_std: float = 0.25

def parse_args() -> Config:
    parser = argparse.ArgumentParser(
        description="XGBoost + CNN + soft voting for 5G uplink modality recognition"
    )
    parser.add_argument("--matlab-out", type=str, required=True)
    parser.add_argument("--out-dir", type=str, default=None)
    parser.add_argument("--seed", type=int, default=2026)

    parser.add_argument("--val-ratio", type=float, default=0.10)
    parser.add_argument("--test-ratio", type=float, default=0.10)
    parser.add_argument("--no-reuse-split", action="store_true")

    parser.add_argument("--image-size", type=int, default=224)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--num-workers", type=int, default=2)

    parser.add_argument("--cnn-epochs", type=int, default=40)
    parser.add_argument("--cnn-lr", type=float, default=1e-3)
    parser.add_argument("--cnn-weight-decay", type=float, default=1e-4)
    parser.add_argument("--cnn-patience", type=int, default=8)
    parser.add_argument("--cnn-loss", type=str, default="focal", choices=["focal", "ce"],
                        help="CNN loss: focal uses weighted focal loss; ce uses weighted cross entropy.")
    parser.add_argument("--cnn-focal-gamma", type=float, default=2.0)
    parser.add_argument("--cnn-text-weight", type=float, default=1.0)
    parser.add_argument("--cnn-audio-weight", type=float, default=2.0)
    parser.add_argument("--cnn-image-weight", type=float, default=2.5)
    parser.add_argument("--cnn-video-weight", type=float, default=1.2)
    parser.add_argument("--no-cnn-augment", action="store_true",
                        help="Disable lightweight spectrogram augmentation for CNN training.")
    parser.add_argument("--cnn-select-audio-image-weight", type=float, default=0.25,
                        help="Extra validation score weight for average audio/image F1 when selecting best CNN epoch.")

    parser.add_argument("--xgb-n-estimators", type=int, default=800)
    parser.add_argument("--xgb-max-depth", type=int, default=4)
    parser.add_argument("--xgb-learning-rate", type=float, default=0.025)
    parser.add_argument("--xgb-subsample", type=float, default=0.85)
    parser.add_argument("--xgb-colsample-bytree", type=float, default=0.85)
    parser.add_argument("--xgb-min-child-weight", type=float, default=2.0)
    parser.add_argument("--xgb-reg-alpha", type=float, default=0.10)
    parser.add_argument("--xgb-reg-lambda", type=float, default=1.50)
    parser.add_argument("--xgb-early-stopping-rounds", type=int, default=60)

    parser.add_argument("--alpha-step", type=float, default=0.01)
    parser.add_argument("--length-oracle-bins", type=int, default=6,
                        help="Number of coarse buckets for weak length prior lo_payload_len_bucket.")
    parser.add_argument("--length-oracle-noise-std", type=float, default=0.25,
                        help="Gaussian noise std added to log(payloadBytesTx) before bucketization.")
    parser.add_argument(
        "--no-length-oracle",
        action="store_true",
        help="Disable length-oracle leakage features and train the strict 58-D blind-only baseline.",
    )
    parser.add_argument(
        "--use-channel-est-features",
        action="store_true",
        help="Add receiver-estimated CSI/RSRP/CIR-like features if available. Use only for ablation, not strict blind-only main results.",
    )
    args = parser.parse_args()

    matlab_out = Path(args.matlab_out).expanduser().resolve()
    if args.out_dir is None:
        project_root = infer_project_root(matlab_out)
        out_dir = project_root / "modality_classifier_results" / f"{matlab_out.name}_xgb_cnn_softvote_lengthoracle_focalcnn"
    else:
        out_dir = Path(args.out_dir).expanduser().resolve()

    return Config(
        matlab_out=str(matlab_out),
        out_dir=str(out_dir),
        seed=args.seed,
        val_ratio=args.val_ratio,
        test_ratio=args.test_ratio,
        reuse_split=not args.no_reuse_split,
        image_size=args.image_size,
        batch_size=args.batch_size,
        num_workers=args.num_workers,
        cnn_epochs=args.cnn_epochs,
        cnn_lr=args.cnn_lr,
        cnn_weight_decay=args.cnn_weight_decay,
        cnn_patience=args.cnn_patience,
        cnn_loss=args.cnn_loss,
        cnn_focal_gamma=args.cnn_focal_gamma,
        cnn_text_weight=args.cnn_text_weight,
        cnn_audio_weight=args.cnn_audio_weight,
        cnn_image_weight=args.cnn_image_weight,
        cnn_video_weight=args.cnn_video_weight,
        cnn_augment=not args.no_cnn_augment,
        cnn_select_audio_image_weight=args.cnn_select_audio_image_weight,
        xgb_n_estimators=args.xgb_n_estimators,
        xgb_max_depth=args.xgb_max_depth,
        xgb_learning_rate=args.xgb_learning_rate,
        xgb_subsample=args.xgb_subsample,
        xgb_colsample_bytree=args.xgb_colsample_bytree,
        xgb_min_child_weight=args.xgb_min_child_weight,
        xgb_reg_alpha=args.xgb_reg_alpha,
        xgb_reg_lambda=args.xgb_reg_lambda,
        xgb_early_stopping_rounds=args.xgb_early_stopping_rounds,
        alpha_step=args.alpha_step,
        enable_length_oracle=not args.no_length_oracle,
        enable_channel_est_features=args.use_channel_est_features,
        length_oracle_bins=args.length_oracle_bins,
        length_oracle_noise_std=args.length_oracle_noise_std,
    )

def infer_project_root(matlab_out: Path) -> Path:
    parts = list(matlab_out.parts)
    if "core_pipeline" in parts:
        idx = parts.index("core_pipeline")
        return Path(*parts[:idx])
    return matlab_out.parent

def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.benchmark = False
    torch.backends.cudnn.deterministic = True

def load_dataset(matlab_out: Path) -> pd.DataFrame:
    feature_path = matlab_out / "near_blind_frontend_features.csv"
    eval_path = matlab_out / "near_blind_eval_labels.csv"

    if not feature_path.exists():
        raise FileNotFoundError(f"Cannot find feature CSV: {feature_path}")
    if not eval_path.exists():
        raise FileNotFoundError(f"Cannot find eval label CSV: {eval_path}")

    feat_df = pd.read_csv(feature_path)
    eval_df = pd.read_csv(eval_path)

    if len(feat_df) != len(eval_df):
        raise ValueError(
            f"Feature/eval row mismatch: {len(feat_df)} vs {len(eval_df)}. "
            "They must come from the same MATLAB run."
        )

    df = pd.concat([eval_df.reset_index(drop=True), feat_df.reset_index(drop=True)], axis=1)
    df = df.loc[:, ~df.columns.duplicated()].copy()

    if "sampleId" not in df.columns:
        df.insert(0, "sampleId", np.arange(1, len(df) + 1))

    if "modality" not in df.columns:
        raise ValueError("near_blind_eval_labels.csv must contain modality column")

    df["modality"] = df["modality"].astype(str).str.lower()
    unknown = sorted(set(df["modality"].unique()) - set(LABEL_ORDER))
    if unknown:
        raise ValueError(f"Unknown modality labels: {unknown}. Expected {LABEL_ORDER}")

    if "sourceFilePath" not in df.columns:
        if "sourceFileName" in df.columns:
            df["sourceFilePath"] = df["sourceFileName"].astype(str)
        else:
            df["sourceFilePath"] = "sample_" + df["sampleId"].astype(str)

    if "spectrumImagePath" not in df.columns:
        raise ValueError("near_blind_eval_labels.csv must contain spectrumImagePath for CNN branch")

    df["sourceFilePath"] = df["sourceFilePath"].astype(str)
    df["spectrumImagePath"] = df["spectrumImagePath"].astype(str)

    ch_path = matlab_out / "near_blind_channel_context.csv"
    if ch_path.exists():
        ch_df = pd.read_csv(ch_path)
        if len(ch_df) == len(df):
            ch_df = ch_df.reset_index(drop=True)
            for col in ch_df.columns:
                if col not in df.columns:
                    df[col] = ch_df[col]
            print(f"[INFO] Loaded optional channel context: {ch_path}")
        else:
            warnings.warn(
                f"Ignore channel context because row count does not match: "
                f"{len(ch_df)} vs {len(df)} at {ch_path}"
            )

    return df

def prepare_features(df: pd.DataFrame, cfg: Config) -> Tuple[pd.DataFrame, List[str]]:
    xdf = pd.DataFrame(index=df.index)
    feature_cols = list(FEATURE_COLS)

    for col in FEATURE_COLS:
        if col in df.columns:
            xdf[col] = df[col]
        else:
            warnings.warn(f"Missing feature column {col}; fill with NaN and impute later")
            xdf[col] = np.nan

    if "estMod" in xdf.columns and not pd.api.types.is_numeric_dtype(xdf["estMod"]):
        xdf["estMod"] = (
            xdf["estMod"]
            .astype(str)
            .str.strip()
            .str.lower()
            .map(EST_MOD_MAP)
            .fillna(0)
            .astype(float)
        )

    for col in FEATURE_COLS:
        xdf[col] = pd.to_numeric(xdf[col], errors="coerce")

    if cfg.enable_length_oracle:
        oracle_df = build_length_oracle_features(
            df,
            seed=cfg.seed,
            n_bins=cfg.length_oracle_bins,
            noise_std=cfg.length_oracle_noise_std,
        )
        for col in oracle_df.columns:
            xdf[col] = oracle_df[col]
        feature_cols = feature_cols + list(oracle_df.columns)
        validate_no_forbidden_leakage(feature_cols)
    else:
        validate_no_leakage(feature_cols)

    if cfg.enable_channel_est_features:
        added = []
        for col in CHANNEL_EST_FEATURE_COLS:
            if col in df.columns:
                xdf[col] = pd.to_numeric(df[col], errors="coerce")
                added.append(col)
            else:
                warnings.warn(f"Channel-est feature {col} is missing; skip it")
        feature_cols = feature_cols + added
        if added:
            print(f"[INFO] Added receiver-estimated channel features: {added}")
        else:
            warnings.warn("--use-channel-est-features was set, but no channel-est features were found.")
        validate_no_forbidden_leakage(feature_cols)

    xdf = xdf.replace([np.inf, -np.inf], np.nan)
    return xdf[feature_cols], feature_cols

def build_length_oracle_features(
        df: pd.DataFrame,
        seed: int = 2026,
        n_bins: int = 6,
        noise_std: float = 0.25,
) -> pd.DataFrame:
    out = pd.DataFrame(index=df.index)

    if "payloadBytesTx" not in df.columns:
        raise ValueError("payloadBytesTx is required for weak length-prior experiment.")

    length = pd.to_numeric(df["payloadBytesTx"], errors="coerce").astype(float)
    length = length.where(length >= 0, np.nan).fillna(0.0)
    log_len = np.log1p(length)

    rng = np.random.default_rng(seed)
    log_len_noisy = log_len + rng.normal(loc=0.0, scale=noise_std, size=len(log_len))

    try:
        bucket = pd.qcut(log_len_noisy, q=max(2, int(n_bins)), labels=False, duplicates="drop")
    except ValueError:
        bucket = pd.cut(log_len_noisy, bins=max(2, int(n_bins)), labels=False, include_lowest=True)

    bucket = pd.Series(bucket, index=df.index).astype(float).fillna(0.0)
    out["lo_payload_len_bucket"] = bucket

    return out[LENGTH_ORACLE_FEATURE_COLS]

def validate_no_leakage(feature_cols: List[str]) -> None:
    bad = [c for c in feature_cols if c in LEAKAGE_COLS]
    if bad:
        raise ValueError(f"Feature leakage detected. Remove these columns: {bad}")

def validate_no_forbidden_leakage(feature_cols: List[str]) -> None:
    allowed = set(LENGTH_ORACLE_FEATURE_COLS) | set(CHANNEL_EST_FEATURE_COLS)
    bad = [c for c in feature_cols if c in LEAKAGE_COLS and c not in allowed]
    if bad:
        raise ValueError(f"Forbidden leakage detected. Remove these columns: {bad}")

def make_or_load_split(df: pd.DataFrame, out_dir: Path, cfg: Config) -> pd.Series:
    split_path = out_dir / "split_index.csv"

    if cfg.reuse_split and split_path.exists():
        old = pd.read_csv(split_path)
        if "sampleId" in old.columns and "split" in old.columns:
            mapping = dict(zip(old["sampleId"], old["split"]))
            split = df["sampleId"].map(mapping)
            if split.notna().all():
                print(f"[INFO] Reusing split: {split_path}")
                return split.astype(str)
            print("[WARN] Existing split does not match current sampleId. Rebuilding split.")

    split = build_group_split_by_source(df, cfg.seed, cfg.val_ratio, cfg.test_ratio)

    split_df = df[["sampleId", "modality", "sourceFilePath"]].copy()
    split_df["split"] = split.values
    split_df.to_csv(split_path, index=False)
    print(f"[INFO] Saved split: {split_path}")
    return split

def build_group_split_by_source(
        df: pd.DataFrame,
        seed: int,
        val_ratio: float,
        test_ratio: float,
) -> pd.Series:
    rng = np.random.default_rng(seed)
    split = pd.Series(index=df.index, dtype=object)

    for label in LABEL_ORDER:
        idx_label = df.index[df["modality"] == label].to_numpy()
        if len(idx_label) == 0:
            raise ValueError(f"No samples for label {label}")

        sources = np.array(sorted(df.loc[idx_label, "sourceFilePath"].astype(str).unique()))
        rng.shuffle(sources)
        n_sources = len(sources)

        if n_sources < 3:
            warnings.warn(
                f"Too few source files for {label} ({n_sources}). Falling back to row-level split for this label."
            )
            idx_shuf = idx_label.copy()
            rng.shuffle(idx_shuf)
            n = len(idx_shuf)
            n_test = max(1, int(round(n * test_ratio)))
            n_val = max(1, int(round(n * val_ratio)))
            if n_val + n_test >= n:
                n_val = max(1, n // 5)
                n_test = max(1, n // 5)
            split.loc[idx_shuf[:n_test]] = "test"
            split.loc[idx_shuf[n_test:n_test + n_val]] = "val"
            split.loc[idx_shuf[n_test + n_val:]] = "train"
            continue

        n_test = max(1, int(round(n_sources * test_ratio)))
        n_val = max(1, int(round(n_sources * val_ratio)))
        if n_test + n_val >= n_sources:
            n_test = max(1, min(n_test, n_sources // 5))
            n_val = max(1, min(n_val, n_sources // 5))

        test_sources = set(sources[:n_test])
        val_sources = set(sources[n_test:n_test + n_val])
        train_sources = set(sources[n_test + n_val:])

        src = df.loc[idx_label, "sourceFilePath"].astype(str)
        split.loc[idx_label[src.isin(train_sources)]] = "train"
        split.loc[idx_label[src.isin(val_sources)]] = "val"
        split.loc[idx_label[src.isin(test_sources)]] = "test"

    if split.isna().any():
        raise RuntimeError("Internal split error: some rows have no split")

    return split.astype(str)

def save_split_summary(df: pd.DataFrame, split: pd.Series, out_dir: Path) -> pd.DataFrame:
    temp = df[["modality", "sourceFilePath"]].copy()
    temp["split"] = split.values
    rows = []
    for sp in ["train", "val", "test"]:
        for lab in LABEL_ORDER:
            mask = (temp["split"] == sp) & (temp["modality"] == lab)
            rows.append({
                "split": sp,
                "modality": lab,
                "n_samples": int(mask.sum()),
                "n_source_files": int(temp.loc[mask, "sourceFilePath"].nunique()),
            })
        mask = temp["split"] == sp
        rows.append({
            "split": sp,
            "modality": "ALL",
            "n_samples": int(mask.sum()),
            "n_source_files": int(temp.loc[mask, "sourceFilePath"].nunique()),
        })
    summary = pd.DataFrame(rows)
    summary.to_csv(out_dir / "split_summary.csv", index=False)
    print("\n===== Split summary =====")
    print(summary.to_string(index=False))
    return summary

class SpectrogramDataset(Dataset):
    def __init__(
            self,
            df: pd.DataFrame,
            indices: np.ndarray,
            y_all: np.ndarray,
            image_size: int,
            augment: bool = False,
    ):
        self.df = df.iloc[indices].reset_index(drop=True)
        self.y = y_all[indices]
        self.image_size = image_size
        self.augment = augment

    def __len__(self) -> int:
        return len(self.df)

    def __getitem__(self, idx: int):
        image_path = str(self.df.loc[idx, "spectrumImagePath"])
        img = load_gray_image(image_path, self.image_size)
        arr = np.asarray(img, dtype=np.float32) / 255.0
        if self.augment:
            arr = augment_spectrogram_array(arr)
        arr = (arr - 0.5) / 0.5
        x = torch.from_numpy(arr).unsqueeze(0)
        y = torch.tensor(int(self.y[idx]), dtype=torch.long)
        return x, y

def load_gray_image(image_path: str, image_size: int) -> Image.Image:
    p = Path(image_path).expanduser()
    if not p.exists():
        warnings.warn(f"Image not found, use blank image: {p}")
        return Image.new("L", (image_size, image_size), color=0)
    try:
        return Image.open(p).convert("L").resize((image_size, image_size))
    except Exception as exc:
        warnings.warn(f"Cannot read image {p}: {exc}. Use blank image.")
        return Image.new("L", (image_size, image_size), color=0)

def augment_spectrogram_array(arr: np.ndarray) -> np.ndarray:
    out = arr.astype(np.float32, copy=True)

    if random.random() < 0.70:
        shift_t = random.randint(-8, 8)
        shift_f = random.randint(-6, 6)
        out = np.roll(out, shift=shift_t, axis=1)
        out = np.roll(out, shift=shift_f, axis=0)

    if random.random() < 0.70:
        gain = 1.0 + random.uniform(-0.12, 0.12)
        offset = random.uniform(-0.04, 0.04)
        out = out * gain + offset

    if random.random() < 0.50:
        out = out + np.random.normal(0.0, 0.015, size=out.shape).astype(np.float32)

    return np.clip(out, 0.0, 1.0)

class SmallSpectrogramCNN(nn.Module):
    def __init__(self, num_classes: int = 4):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(1, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),

            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),

            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),

            nn.Conv2d(128, 192, kernel_size=3, padding=1),
            nn.BatchNorm2d(192),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, 1)),
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Dropout(0.25),
            nn.Linear(192, 96),
            nn.ReLU(inplace=True),
            nn.Dropout(0.20),
            nn.Linear(96, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.classifier(self.features(x))

def train_xgboost(
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray,
        cfg: Config,
) -> XGBClassifier:
    sample_weight = compute_sample_weight(class_weight="balanced", y=y_train)

    model = XGBClassifier(
        objective="multi:softprob",
        num_class=len(LABEL_ORDER),
        n_estimators=cfg.xgb_n_estimators,
        max_depth=cfg.xgb_max_depth,
        learning_rate=cfg.xgb_learning_rate,
        subsample=cfg.xgb_subsample,
        colsample_bytree=cfg.xgb_colsample_bytree,
        min_child_weight=cfg.xgb_min_child_weight,
        reg_alpha=cfg.xgb_reg_alpha,
        reg_lambda=cfg.xgb_reg_lambda,
        eval_metric="mlogloss",
        tree_method="hist",
        random_state=cfg.seed,
        n_jobs=-1,
    )

    try:
        model.fit(
            X_train,
            y_train,
            sample_weight=sample_weight,
            eval_set=[(X_val, y_val)],
            verbose=False,
            early_stopping_rounds=cfg.xgb_early_stopping_rounds,
        )
    except TypeError:
        model.fit(
            X_train,
            y_train,
            sample_weight=sample_weight,
            eval_set=[(X_val, y_val)],
            verbose=False,
        )

    return model

class WeightedFocalLoss(nn.Module):
    def __init__(self, class_weights: torch.Tensor, gamma: float = 2.0):
        super().__init__()
        self.register_buffer("class_weights", class_weights.float())
        self.gamma = float(gamma)

    def forward(self, logits: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        log_probs = F.log_softmax(logits, dim=1)
        probs = torch.exp(log_probs)
        target = target.long()

        log_pt = log_probs.gather(1, target.view(-1, 1)).squeeze(1)
        pt = probs.gather(1, target.view(-1, 1)).squeeze(1).clamp(min=1e-8, max=1.0)
        weights = self.class_weights[target]

        loss = -weights * torch.pow(1.0 - pt, self.gamma) * log_pt
        return loss.mean()

def make_cnn_class_weights(y: np.ndarray, cfg: Config) -> np.ndarray:
    base = compute_class_weights(y, len(LABEL_ORDER)).astype(np.float32)
    focus = np.array([
        cfg.cnn_text_weight,
        cfg.cnn_audio_weight,
        cfg.cnn_image_weight,
        cfg.cnn_video_weight,
    ], dtype=np.float32)
    weights = base * focus
    weights = weights / (np.mean(weights) + 1e-12)
    return weights.astype(np.float32)

def train_cnn(
        df: pd.DataFrame,
        split: pd.Series,
        y_all: np.ndarray,
        cfg: Config,
        out_dir: Path,
) -> Tuple[SmallSpectrogramCNN, torch.device]:
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"[CNN] device={device}")

    train_idx = np.where(split.values == "train")[0]
    val_idx = np.where(split.values == "val")[0]

    train_ds = SpectrogramDataset(df, train_idx, y_all, cfg.image_size, augment=cfg.cnn_augment)
    val_ds = SpectrogramDataset(df, val_idx, y_all, cfg.image_size, augment=False)

    train_loader = DataLoader(
        train_ds,
        batch_size=cfg.batch_size,
        shuffle=True,
        num_workers=cfg.num_workers,
        pin_memory=(device.type == "cuda"),
    )
    val_loader = DataLoader(
        val_ds,
        batch_size=cfg.batch_size,
        shuffle=False,
        num_workers=cfg.num_workers,
        pin_memory=(device.type == "cuda"),
    )

    model = SmallSpectrogramCNN(num_classes=len(LABEL_ORDER)).to(device)

    class_weights = make_cnn_class_weights(y_all[train_idx], cfg)
    class_weight_tensor = torch.tensor(class_weights, dtype=torch.float32, device=device)
    if cfg.cnn_loss.lower() == "focal":
        criterion = WeightedFocalLoss(class_weight_tensor, gamma=cfg.cnn_focal_gamma)
        print(f"[CNN] loss=weighted focal, gamma={cfg.cnn_focal_gamma}, class_weights={class_weights.tolist()}")
    else:
        criterion = nn.CrossEntropyLoss(weight=class_weight_tensor)
        print(f"[CNN] loss=weighted cross entropy, class_weights={class_weights.tolist()}")
    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=cfg.cnn_lr,
        weight_decay=cfg.cnn_weight_decay,
    )

    best_score = -1.0
    best_f1 = -1.0
    best_epoch = 0
    bad_epochs = 0
    best_path = out_dir / "cnn_spectrogram_focal_best.pt"
    history = []

    for epoch in range(1, cfg.cnn_epochs + 1):
        model.train()
        total_loss = 0.0
        n_seen = 0

        for xb, yb in train_loader:
            xb = xb.to(device, non_blocking=True)
            yb = yb.to(device, non_blocking=True)

            optimizer.zero_grad(set_to_none=True)
            logits = model(xb)
            loss = criterion(logits, yb)
            loss.backward()
            optimizer.step()

            total_loss += float(loss.item()) * xb.size(0)
            n_seen += xb.size(0)

        train_loss = total_loss / max(1, n_seen)
        val_prob = predict_cnn_loader(model, val_loader, device)
        y_val = y_all[val_idx]
        val_pred = val_prob.argmax(axis=1)
        val_acc = accuracy_score(y_val, val_pred)
        val_f1 = f1_score(y_val, val_pred, average="macro", zero_division=0)
        val_report = classification_report(
            y_val,
            val_pred,
            target_names=LABEL_ORDER,
            output_dict=True,
            zero_division=0,
        )
        val_audio_f1 = float(val_report["audio"]["f1-score"])
        val_image_f1 = float(val_report["image"]["f1-score"])
        val_audio_image_f1 = 0.5 * (val_audio_f1 + val_image_f1)
        val_score = float(val_f1 + cfg.cnn_select_audio_image_weight * val_audio_image_f1)

        history.append({
            "epoch": epoch,
            "train_loss": train_loss,
            "val_accuracy": val_acc,
            "val_macro_f1": val_f1,
            "val_audio_f1": val_audio_f1,
            "val_image_f1": val_image_f1,
            "val_audio_image_f1": val_audio_image_f1,
            "val_selection_score": val_score,
        })
        print(
            f"[CNN] epoch={epoch:03d} loss={train_loss:.4f} "
            f"val_acc={val_acc:.4f} val_macro_f1={val_f1:.4f} "
            f"audio_f1={val_audio_f1:.4f} image_f1={val_image_f1:.4f} "
            f"select_score={val_score:.4f}"
        )

        if val_score > best_score:
            best_score = val_score
            best_f1 = val_f1
            best_epoch = epoch
            bad_epochs = 0
            torch.save({
                "model_state_dict": model.state_dict(),
                "best_score": best_score,
                "best_f1": best_f1,
                "best_epoch": best_epoch,
                "label_order": LABEL_ORDER,
                "config": asdict(cfg),
            }, best_path)
        else:
            bad_epochs += 1
            if bad_epochs >= cfg.cnn_patience:
                print(f"[CNN] early stopping at epoch {epoch}; best_epoch={best_epoch}, best_f1={best_f1:.4f}, best_score={best_score:.4f}")
                break

    pd.DataFrame(history).to_csv(out_dir / "cnn_training_history.csv", index=False)

    ckpt = torch.load(best_path, map_location=device)
    model.load_state_dict(ckpt["model_state_dict"])
    return model, device

def compute_class_weights(y: np.ndarray, num_classes: int) -> np.ndarray:
    weights = np.ones(num_classes, dtype=np.float32)
    total = len(y)
    for c in range(num_classes):
        n = np.sum(y == c)
        if n > 0:
            weights[c] = total / (num_classes * n)
    return weights

def predict_cnn_loader(
        model: nn.Module,
        loader: DataLoader,
        device: torch.device,
) -> np.ndarray:
    model.eval()
    probs = []
    with torch.no_grad():
        for xb, _ in loader:
            xb = xb.to(device, non_blocking=True)
            logits = model(xb)
            p = torch.softmax(logits, dim=1).cpu().numpy()
            probs.append(p)
    if not probs:
        return np.zeros((0, len(LABEL_ORDER)), dtype=np.float32)
    return np.vstack(probs)

def predict_cnn_indices(
        model: nn.Module,
        df: pd.DataFrame,
        indices: np.ndarray,
        y_all: np.ndarray,
        cfg: Config,
        device: torch.device,
) -> np.ndarray:
    ds = SpectrogramDataset(df, indices, y_all, cfg.image_size, augment=False)
    loader = DataLoader(
        ds,
        batch_size=cfg.batch_size,
        shuffle=False,
        num_workers=cfg.num_workers,
        pin_memory=(device.type == "cuda"),
    )
    return predict_cnn_loader(model, loader, device)

def tune_softvote_alpha(
        y_true: np.ndarray,
        prob_xgb: np.ndarray,
        prob_cnn: np.ndarray,
        step: float,
) -> Dict[str, float]:
    best = {
        "alpha_xgb": 0.5,
        "alpha_cnn": 0.5,
        "macro_f1": -1.0,
        "accuracy": -1.0,
    }

    alphas = np.arange(0.0, 1.0 + 1e-9, step)
    for alpha in alphas:
        prob = alpha * prob_xgb + (1.0 - alpha) * prob_cnn
        pred = prob.argmax(axis=1)
        f1 = f1_score(y_true, pred, average="macro", zero_division=0)
        acc = accuracy_score(y_true, pred)
        if f1 > best["macro_f1"]:
            best = {
                "alpha_xgb": float(alpha),
                "alpha_cnn": float(1.0 - alpha),
                "macro_f1": float(f1),
                "accuracy": float(acc),
            }
    return best

def evaluate_probability(y_true: np.ndarray, prob: np.ndarray, name: str) -> Dict:
    pred = prob.argmax(axis=1)
    report_text = classification_report(
        y_true,
        pred,
        target_names=LABEL_ORDER,
        digits=4,
        zero_division=0,
    )
    report_dict = classification_report(
        y_true,
        pred,
        target_names=LABEL_ORDER,
        output_dict=True,
        zero_division=0,
    )
    cm = confusion_matrix(y_true, pred, labels=list(range(len(LABEL_ORDER))))
    return {
        "name": name,
        "accuracy": float(accuracy_score(y_true, pred)),
        "macro_precision": float(precision_score(y_true, pred, average="macro", zero_division=0)),
        "macro_recall": float(recall_score(y_true, pred, average="macro", zero_division=0)),
        "macro_f1": float(f1_score(y_true, pred, average="macro", zero_division=0)),
        "weighted_f1": float(f1_score(y_true, pred, average="weighted", zero_division=0)),
        "classification_report_text": report_text,
        "classification_report": report_dict,
        "confusion_matrix": cm.tolist(),
    }

def save_confusion_matrix(cm: List[List[int]], path: Path, title: str) -> None:
    mat = np.array(cm, dtype=int)
    fig, ax = plt.subplots(figsize=(6.5, 5.5))
    im = ax.imshow(mat, interpolation="nearest")
    fig.colorbar(im, ax=ax)
    ax.set(
        xticks=np.arange(len(LABEL_ORDER)),
        yticks=np.arange(len(LABEL_ORDER)),
        xticklabels=LABEL_ORDER,
        yticklabels=LABEL_ORDER,
        ylabel="True label",
        xlabel="Predicted label",
        title=title,
    )
    plt.setp(ax.get_xticklabels(), rotation=30, ha="right", rotation_mode="anchor")

    for i in range(mat.shape[0]):
        for j in range(mat.shape[1]):
            ax.text(j, i, str(mat[i, j]), ha="center", va="center")

    fig.tight_layout()
    fig.savefig(path, dpi=220)
    plt.close(fig)

def save_xgb_feature_importance(
        model: XGBClassifier,
        feature_cols: List[str],
        out_dir: Path,
) -> pd.DataFrame:
    booster = model.get_booster()
    gain = booster.get_score(importance_type="gain")
    weight = booster.get_score(importance_type="weight")
    cover = booster.get_score(importance_type="cover")

    rows = []
    for i, col in enumerate(feature_cols):
        key = f"f{i}"
        rows.append({
            "feature": col,
            "gain": float(gain.get(key, 0.0)),
            "weight": float(weight.get(key, 0.0)),
            "cover": float(cover.get(key, 0.0)),
        })
    imp = pd.DataFrame(rows).sort_values("gain", ascending=False).reset_index(drop=True)
    imp.to_csv(out_dir / "xgboost_58feat_lengthoracle_focalcnn_feature_importance.csv", index=False)

    fig, ax = plt.subplots(figsize=(8, max(5, 0.32 * len(feature_cols))))
    plot_df = imp.sort_values("gain", ascending=True)
    ax.barh(plot_df["feature"], plot_df["gain"])
    ax.set_xlabel("XGBoost importance: gain")
    ax.set_title("58 blind-only + length-oracle feature importance")
    fig.tight_layout()
    fig.savefig(out_dir / "xgboost_58feat_lengthoracle_focalcnn_feature_importance.png", dpi=220)
    plt.close(fig)

    return imp

def make_prediction_dataframe(
        df: pd.DataFrame,
        indices: np.ndarray,
        y_true: np.ndarray,
        prob_xgb: np.ndarray,
        prob_cnn: np.ndarray,
        prob_soft: np.ndarray,
        split_name: str,
) -> pd.DataFrame:
    pred = prob_soft.argmax(axis=1)
    out = pd.DataFrame({
        "sampleId": df.iloc[indices]["sampleId"].values,
        "split": split_name,
        "true_label": [ID_TO_LABEL[int(x)] for x in y_true],
        "pred_label_softvote": [ID_TO_LABEL[int(x)] for x in pred],
        "correct_softvote": (pred == y_true).astype(int),
    })

    pred_xgb = prob_xgb.argmax(axis=1)
    pred_cnn = prob_cnn.argmax(axis=1)
    out["pred_label_xgb"] = [ID_TO_LABEL[int(x)] for x in pred_xgb]
    out["pred_label_cnn"] = [ID_TO_LABEL[int(x)] for x in pred_cnn]
    out["correct_xgb"] = (pred_xgb == y_true).astype(int)
    out["correct_cnn"] = (pred_cnn == y_true).astype(int)

    for k, lab in ID_TO_LABEL.items():
        out[f"xgb_prob_{lab}"] = prob_xgb[:, k]
        out[f"cnn_prob_{lab}"] = prob_cnn[:, k]
        out[f"softvote_prob_{lab}"] = prob_soft[:, k]

    context_cols = [
        "trueSnrDb",
        "snrBucket",
        "payloadBytes",
        "sourceFileName",
        "sourceFilePath",
        "spectrumImagePath",
        "waveformImagePath",
        "annotatedWaveformPath",
        "open5gsValidated",
        "open5gsReceivedFilePath",
        "open5gsSha256",
        "encMode",
        "ser",
        "evm",
    ]
    for col in context_cols:
        if col in df.columns:
            out[col] = df.iloc[indices][col].values

    return out

def main() -> None:
    cfg = parse_args()
    set_seed(cfg.seed)

    matlab_out = Path(cfg.matlab_out)
    out_dir = Path(cfg.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    with open(out_dir / "config.json", "w", encoding="utf-8") as f:
        json.dump(asdict(cfg), f, indent=2, ensure_ascii=False)

    print("[INFO] MATLAB output:", matlab_out)
    print("[INFO] Result output:", out_dir)

    df = load_dataset(matlab_out)
    X_df, feature_cols = prepare_features(df, cfg=cfg)
    y = df["modality"].map(LABEL_TO_ID).astype(int).to_numpy()

    split = make_or_load_split(df, out_dir, cfg)
    save_split_summary(df, split, out_dir)

    train_idx = np.where(split.values == "train")[0]
    val_idx = np.where(split.values == "val")[0]
    test_idx = np.where(split.values == "test")[0]

    if len(train_idx) == 0 or len(val_idx) == 0 or len(test_idx) == 0:
        raise ValueError("Empty train/val/test split. Check source files and split ratios.")

    y_train = y[train_idx]
    y_val = y[val_idx]
    y_test = y[test_idx]

    print("\n[1/5] Preprocess 58-D blind features + optional length-oracle features")
    print(f"[INFO] enable_length_oracle={cfg.enable_length_oracle}")
    print(f"[INFO] enable_channel_est_features={cfg.enable_channel_est_features}")
    imputer = SimpleImputer(strategy="median")
    X_train = imputer.fit_transform(X_df.iloc[train_idx])
    X_val = imputer.transform(X_df.iloc[val_idx])
    X_test = imputer.transform(X_df.iloc[test_idx])

    print("\n[2/5] Train XGBoost on 58-D blind features + length-oracle features")
    print("[XGB] Features:")
    for i, col in enumerate(feature_cols, start=1):
        print(f"  {i:02d}. {col}")
    xgb_model = train_xgboost(X_train, y_train, X_val, y_val, cfg)
    prob_xgb_val = xgb_model.predict_proba(X_val)
    prob_xgb_test = xgb_model.predict_proba(X_test)

    print("\n[3/5] Train CNN on burst spectrogram images")
    cnn_model, device = train_cnn(df, split, y, cfg, out_dir)
    prob_cnn_val = predict_cnn_indices(cnn_model, df, val_idx, y, cfg, device)
    prob_cnn_test = predict_cnn_indices(cnn_model, df, test_idx, y, cfg, device)

    print("\n[4/5] Tune soft-voting weight on validation set")
    alpha_info = tune_softvote_alpha(y_val, prob_xgb_val, prob_cnn_val, cfg.alpha_step)
    alpha_xgb = alpha_info["alpha_xgb"]
    alpha_cnn = alpha_info["alpha_cnn"]
    print(f"[SoftVote] alpha_xgb={alpha_xgb:.2f}, alpha_cnn={alpha_cnn:.2f}, val_macro_f1={alpha_info['macro_f1']:.4f}")

    prob_soft_val = alpha_xgb * prob_xgb_val + alpha_cnn * prob_cnn_val
    prob_soft_test = alpha_xgb * prob_xgb_test + alpha_cnn * prob_cnn_test

    print("\n[5/5] Evaluate")
    reports = {
        "label_order": LABEL_ORDER,
        "feature_cols": feature_cols,
        "length_oracle_raw_cols": LENGTH_ORACLE_RAW_COLS if cfg.enable_length_oracle else [],
        "length_oracle_feature_cols": LENGTH_ORACLE_FEATURE_COLS if cfg.enable_length_oracle else [],
        "channel_est_feature_cols": [c for c in CHANNEL_EST_FEATURE_COLS if c in feature_cols],
        "softvote_alpha": alpha_info,
        "val_xgboost": evaluate_probability(y_val, prob_xgb_val, "val_xgboost"),
        "val_cnn": evaluate_probability(y_val, prob_cnn_val, "val_cnn"),
        "val_softvote": evaluate_probability(y_val, prob_soft_val, "val_softvote"),
        "test_xgboost": evaluate_probability(y_test, prob_xgb_test, "test_xgboost"),
        "test_cnn": evaluate_probability(y_test, prob_cnn_test, "test_cnn"),
        "test_softvote": evaluate_probability(y_test, prob_soft_test, "test_softvote"),
    }

    with open(out_dir / "eval_report_xgb_cnn_softvote_lengthoracle_focalcnn.json", "w", encoding="utf-8") as f:
        json.dump(reports, f, indent=2, ensure_ascii=False)

    print("\n===== TEST XGBoost =====")
    print(reports["test_xgboost"]["classification_report_text"])
    print("\n===== TEST CNN =====")
    print(reports["test_cnn"]["classification_report_text"])
    print("\n===== TEST SoftVote =====")
    print(reports["test_softvote"]["classification_report_text"])

    save_confusion_matrix(
        reports["test_xgboost"]["confusion_matrix"],
        out_dir / "confusion_matrix_test_xgboost_lengthoracle_focalcnn.png",
        "Test XGBoost",
    )
    save_confusion_matrix(
        reports["test_cnn"]["confusion_matrix"],
        out_dir / "confusion_matrix_test_cnn_lengthoracle_focalcnn.png",
        "Test CNN",
    )
    save_confusion_matrix(
        reports["test_softvote"]["confusion_matrix"],
        out_dir / "confusion_matrix_test_softvote_lengthoracle_focalcnn.png",
        "Test Soft Voting",
    )

    pred_val = make_prediction_dataframe(
        df, val_idx, y_val, prob_xgb_val, prob_cnn_val, prob_soft_val, "val"
    )
    pred_test = make_prediction_dataframe(
        df, test_idx, y_test, prob_xgb_test, prob_cnn_test, prob_soft_test, "test"
    )
    pd.concat([pred_val, pred_test], ignore_index=True).to_csv(
        out_dir / "predictions_xgb_cnn_softvote_lengthoracle_focalcnn.csv",
        index=False,
    )
    pred_test.to_csv(out_dir / "test_predictions_xgb_cnn_softvote_lengthoracle_focalcnn.csv", index=False)

    feature_importance = save_xgb_feature_importance(xgb_model, feature_cols, out_dir)
    print("\n===== Top XGBoost feature importance =====")
    print(feature_importance.head(15).to_string(index=False))

    joblib.dump(xgb_model, out_dir / "xgboost_58feat_lengthoracle_focalcnn_model.joblib")
    joblib.dump(imputer, out_dir / "xgboost_58feat_lengthoracle_focalcnn_imputer.joblib")
    pd.DataFrame({"feature": feature_cols}).to_csv(out_dir / "used_feature_columns.csv", index=False)
    torch.save(
        {
            "model_state_dict": cnn_model.state_dict(),
            "label_order": LABEL_ORDER,
            "config": asdict(cfg),
        },
        out_dir / "cnn_spectrogram_model_final.pt",
    )

    with open(out_dir / "label_mapping.json", "w", encoding="utf-8") as f:
        json.dump({"label_to_id": LABEL_TO_ID, "id_to_label": ID_TO_LABEL}, f, indent=2, ensure_ascii=False)

    print("\n===== Saved outputs =====")
    print("out_dir:", out_dir)
    print("report :", out_dir / "eval_report_xgb_cnn_softvote_lengthoracle_focalcnn.json")
    print("pred   :", out_dir / "test_predictions_xgb_cnn_softvote_lengthoracle_focalcnn.csv")
    print("cm     :", out_dir / "confusion_matrix_test_softvote_lengthoracle_focalcnn.png")
    print("xgb    :", out_dir / "xgboost_58feat_lengthoracle_focalcnn_model.joblib")
    print("cnn    :", out_dir / "cnn_spectrogram_model_final.pt")

if __name__ == "__main__":
    main()
