from __future__ import annotations

import argparse
import json
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.model_selection import train_test_split


LABELS_4WAY = ["text", "audio", "image", "video"]
LABELS_AIV_3WAY = ["audio", "image", "video"]


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--task",
        type=str,
        default="modality_4way",
        choices=["modality_4way", "audio_image_video_3way"],
    )

    parser.add_argument(
        "--features_csv",
        type=str,
        default=str(
            Path(
                "~/PycharmProjects/researchtopic/pusch_plus/core_pipeline/capture_parse_outputs_multiclass/enc_streamxor_realistic/near_blind_frontend_features.csv"
            ).expanduser().resolve()
        ),
    )
    parser.add_argument(
        "--labels_csv",
        type=str,
        default=str(
            Path(
                "~/PycharmProjects/researchtopic/pusch_plus/core_pipeline/capture_parse_outputs_multiclass/enc_streamxor_realistic/near_blind_eval_labels.csv"
            ).expanduser().resolve()
        ),
    )
    parser.add_argument(
        "--model_path",
        type=str,
        default=str(
            Path(
                "~/PycharmProjects/researchtopic/pusch_plus/modality_classifier_results/enc_streamxor_realistic/modality_4way_best_model.joblib"
            ).expanduser().resolve()
        ),
    )
    parser.add_argument(
        "--out_dir",
        type=str,
        default=str(
            Path(
                "~/PycharmProjects/researchtopic/pusch_plus/modality_eval/enc_streamxor_realistic"
            ).expanduser().resolve()
        ),
    )
    parser.add_argument("--random_seed", type=int, default=2026)

    return parser.parse_args()


def normalize_modality_label(x: object) -> str:
    s = str(x).strip().lower()

    mapping = {
        "text": "text",
        "txt": "text",
        "audio": "audio",
        "speech": "audio",
        "voice": "audio",
        "image": "image",
        "img": "image",
        "picture": "image",
        "photo": "image",
        "video": "video",
        "vid": "video",
    }

    if s not in mapping:
        raise ValueError(f"未知 modality 标签: {x}")
    return mapping[s]


def load_csv(path: str) -> pd.DataFrame:
    p = Path(path).expanduser().resolve()
    if not p.exists():
        raise FileNotFoundError(f"找不到文件: {p}")
    return pd.read_csv(p)


def build_feature_table(df_feat: pd.DataFrame) -> pd.DataFrame:
    feature_cols_num = [
        "snr",
        "estNfft",
        "estNcp",
        "cfoAbs",
        "cpMetric",
        "tfMetric",
        "jointScore",
        "burstWidth",
        "rxPAPR",
        "rxSpecFlatness",
        "rxRMS",
        "rxSkewness",
        "rxKurtosis",
        "frameEnergyVar",
        "specCentroidMean",
        "specCentroidStd",
        "specFluxMean",
    ]
    feature_cols_cat = ["estMod"]

    keep_cols = feature_cols_num + feature_cols_cat
    missing = [c for c in keep_cols if c not in df_feat.columns]
    if missing:
        raise ValueError(f"features_csv 缺少前端特征列: {missing}")

    X = df_feat[keep_cols].copy()

    for col in X.columns:
        if pd.api.types.is_numeric_dtype(X[col]):
            X[col] = X[col].replace([np.inf, -np.inf], np.nan)
            too_large = X[col].abs() > 1e12
            X.loc[too_large, col] = np.nan

    return X


def prepare_task(df_feat: pd.DataFrame, df_lab: pd.DataFrame, task: str):
    if "modality" not in df_lab.columns:
        raise ValueError("labels_csv 缺少 modality 列。")

    df_lab = df_lab.copy()
    df_lab["modality"] = df_lab["modality"].map(normalize_modality_label)

    df_all = pd.concat(
        [
            df_feat.reset_index(drop=True),
            df_lab.reset_index(drop=True),
        ],
        axis=1,
    )
    df_all = df_all.loc[:, ~df_all.columns.duplicated()].copy()

    if task == "modality_4way":
        df_task = df_all.copy()
        labels = LABELS_4WAY
        task_name = "modality_classification_4way"

    elif task == "audio_image_video_3way":
        df_task = df_all[df_all["modality"].isin(LABELS_AIV_3WAY)].copy()
        labels = LABELS_AIV_3WAY
        task_name = "modality_classification_audio_image_video_3way"

    else:
        raise ValueError(f"Unsupported task: {task}")

    X_all = build_feature_table(df_task).reset_index(drop=True)
    y_all = df_task["modality"].astype(str).reset_index(drop=True)
    meta_all = df_task.reset_index(drop=True)

    return X_all, y_all, meta_all, labels, task_name


def recreate_test_split(X_all: pd.DataFrame, y_all: pd.Series, meta_all: pd.DataFrame, random_seed: int):
    X_all = X_all.copy().reset_index(drop=True)
    y_all = y_all.reset_index(drop=True)
    meta_all = meta_all.reset_index(drop=True)

    X_all["__row_id__"] = np.arange(len(X_all))

    X_train, X_temp, y_train, y_temp, meta_train, meta_temp = train_test_split(
        X_all,
        y_all,
        meta_all,
        test_size=0.30,
        random_state=random_seed,
        stratify=y_all,
    )

    X_val, X_test, y_val, y_test, meta_val, meta_test = train_test_split(
        X_temp,
        y_temp,
        meta_temp,
        test_size=1 / 3,
        random_state=random_seed,
        stratify=y_temp,
    )

    return X_train, X_val, X_test, y_train, y_val, y_test, meta_train, meta_val, meta_test


def save_confusion_matrix(cm, labels, out_path, title):
    fig, ax = plt.subplots(figsize=(6.5, 5.5))
    im = ax.imshow(cm, interpolation="nearest")
    ax.figure.colorbar(im, ax=ax)

    ax.set(
        xticks=np.arange(len(labels)),
        yticks=np.arange(len(labels)),
        xticklabels=labels,
        yticklabels=labels,
        ylabel="True label",
        xlabel="Predicted label",
        title=title,
    )

    plt.setp(ax.get_xticklabels(), rotation=30, ha="right", rotation_mode="anchor")

    thresh = cm.max() / 2.0 if cm.size > 0 else 0.0
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(
                j,
                i,
                format(cm[i, j], "d"),
                ha="center",
                va="center",
                color="white" if cm[i, j] > thresh else "black",
            )

    fig.tight_layout()
    fig.savefig(out_path, dpi=180, bbox_inches="tight")
    plt.close(fig)


def main():
    args = parse_args()
    out_dir = Path(args.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    df_feat = load_csv(args.features_csv).reset_index(drop=True)
    df_lab = load_csv(args.labels_csv).reset_index(drop=True)

    X_all, y_all, meta_all, labels, task_name = prepare_task(df_feat, df_lab, args.task)

    _, _, X_test, _, _, y_test, _, _, meta_test = recreate_test_split(
        X_all=X_all,
        y_all=y_all,
        meta_all=meta_all,
        random_seed=args.random_seed,
    )

    test_row_ids = X_test["__row_id__"].to_numpy()
    X_test_model = X_test.drop(columns=["__row_id__"]).copy()

    model = joblib.load(str(Path(args.model_path).expanduser().resolve()))

    if not hasattr(model, "feature_names_in_"):
        raise ValueError("模型没有 feature_names_in_ 属性，无法自动对齐特征顺序。")

    expected_feature_order = list(model.feature_names_in_)
    missing = [c for c in expected_feature_order if c not in X_test_model.columns]
    if missing:
        raise ValueError(f"X_test_model 缺少训练特征列: {missing}")

    X_test_model = X_test_model.loc[:, expected_feature_order].copy()

    print("[INFO] model.feature_names_in_ =", expected_feature_order)
    print("[INFO] X_test_model.columns   =", list(X_test_model.columns))

    pred_test = model.predict(X_test_model)

    acc = accuracy_score(y_test, pred_test)
    macro_precision = precision_score(y_test, pred_test, average="macro", zero_division=0)
    macro_recall = recall_score(y_test, pred_test, average="macro", zero_division=0)
    macro_f1 = f1_score(y_test, pred_test, average="macro")

    print(f"\n===== {task_name} =====")
    print(f"[TEST] accuracy        = {acc:.4f}")
    print(f"[TEST] macro-precision = {macro_precision:.4f}")
    print(f"[TEST] macro-recall    = {macro_recall:.4f}")
    print(f"[TEST] macro-F1        = {macro_f1:.4f}")
    print(classification_report(y_test, pred_test, labels=labels, zero_division=0))

    cm = confusion_matrix(y_test, pred_test, labels=labels)
    cm_path = out_dir / f"{args.task}_confusion_matrix.png"
    save_confusion_matrix(
        cm=cm,
        labels=labels,
        out_path=cm_path,
        title=f"Confusion Matrix - {task_name}",
    )

    pred_df = X_test_model.copy().reset_index(drop=True)
    meta_test = meta_test.reset_index(drop=True)
    pred_df["row_id"] = test_row_ids
    pred_df["y_true"] = list(pd.Series(y_test).reset_index(drop=True))
    pred_df["y_pred"] = list(pd.Series(pred_test).reset_index(drop=True))

    extra_meta_cols = [
        "modality",
        "payloadType",
        "payloadBytes",
        "sourceFileName",
        "sourceFilePath",
        "sourceSubtype",
        "encEnabled",
        "encMode",
        "payloadBytesPlain",
        "payloadBytesTx",
        "lengthLeakMode",
        "nonceHex",
    ]
    for c in extra_meta_cols:
        if c in meta_test.columns:
            pred_df[c] = meta_test[c]

    pred_csv = out_dir / f"{args.task}_test_predictions.csv"
    pred_df.to_csv(pred_csv, index=False, encoding="utf-8-sig")

    report = {
        "task": task_name,
        "test_accuracy": float(acc),
        "test_macro_precision": float(macro_precision),
        "test_macro_recall": float(macro_recall),
        "test_macro_f1": float(macro_f1),
        "labels": labels,
        "n_test": int(len(X_test_model)),
        "features_csv": str(Path(args.features_csv).expanduser().resolve()),
        "labels_csv": str(Path(args.labels_csv).expanduser().resolve()),
        "model_path": str(Path(args.model_path).expanduser().resolve()),
        "prediction_csv": str(pred_csv),
        "confusion_matrix_png": str(cm_path),
        "strict_principle": "prediction_only_uses_frontend_features_truth_only_used_for_evaluation",
    }

    with open(out_dir / f"{args.task}_eval_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"\nSaved results to: {out_dir}")


if __name__ == "__main__":
    main()