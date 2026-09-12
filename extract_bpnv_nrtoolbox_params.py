
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from pathlib import Path
import pandas as pd
import numpy as np


def read_csv(path: Path):
    if path.exists():
        return pd.read_csv(path)
    return None


def find_sample_id_by_text(packet_df, query_text="BPNv"):
    """
    优先从 sourceFilePath 指向的文本文件中查找 BPNv。
    如果加密样本中 CSV 不直接保存明文，这是最可靠的方式。
    """
    if packet_df is None or packet_df.empty:
        return None

    if "sampleId" not in packet_df.columns:
        return None

    candidate_rows = packet_df.copy()

    if "modality" in candidate_rows.columns:
        candidate_rows = candidate_rows[
            candidate_rows["modality"].astype(str).str.lower() == "text"
        ]

    # 1. 先查 sourceFileName 是否含有 BPNv
    if "sourceFileName" in candidate_rows.columns:
        mask = candidate_rows["sourceFileName"].astype(str).str.contains(
            query_text, case=False, na=False
        )
        if mask.any():
            return int(candidate_rows.loc[mask, "sampleId"].iloc[0])

    # 2. 再打开 sourceFilePath 对应的文本文件查内容
    if "sourceFilePath" in candidate_rows.columns:
        for _, row in candidate_rows.iterrows():
            fp = str(row.get("sourceFilePath", ""))
            if not fp or fp.lower() == "nan":
                continue

            path = Path(fp)
            if not path.exists():
                continue

            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            if query_text in text:
                return int(row["sampleId"])

    return None


def get_row_by_sample_id(df, sample_id):
    if df is None or df.empty:
        return {}

    if "sampleId" not in df.columns:
        return {}

    hit = df[df["sampleId"].astype(str) == str(sample_id)]
    if hit.empty:
        return {}

    return hit.iloc[0].to_dict()


def pick(row, *names):
    """
    从一行 dict 中按候选字段名取值。
    """
    if not row:
        return None

    lower_map = {str(k).lower(): k for k in row.keys()}

    for name in names:
        key = lower_map.get(name.lower())
        if key is not None:
            val = row.get(key)
            if pd.notna(val):
                return val

    return None


def pick_with_key(row, *names):
    if not row:
        return None, None

    lower_map = {str(k).lower(): k for k in row.keys()}

    for name in names:
        key = lower_map.get(name.lower())
        if key is not None:
            val = row.get(key)
            if pd.notna(val):
                return key, val

    return None, None


def num(x):
    try:
        if x is None:
            return None
        if isinstance(x, str) and x.strip() == "":
            return None
        return float(x)
    except Exception:
        return None


def fmt_err(ref, est, abs_ref=False):
    r = num(ref)
    e = num(est)

    if r is None or e is None:
        return None, None

    if abs_ref:
        r = abs(r)

    err = e - r
    return err, abs(err)


def add_compare(rows, name, ref_key, ref_val, est_key, est_val, method="", abs_ref=False):
    err, abs_err = fmt_err(ref_val, est_val, abs_ref=abs_ref)

    rows.append({
        "参数": name,
        "真实/参考字段": ref_key,
        "真实/参考值": ref_val,
        "估计/解析字段": est_key,
        "估计/解析值": est_val,
        "误差(估计-真实)": err,
        "绝对误差": abs_err,
        "估计方法": method
    })


def safe_int(x, default=0):
    try:
        return int(float(x))
    except Exception:
        return default


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--matlab-out", required=True, help="最新 MATLAB 输出目录")
    ap.add_argument("--sample-id", default=None, help="如果知道 BPNv 的 sampleId，可直接指定")
    ap.add_argument("--query-text", default="BPNv", help="要查找的文本内容")
    ap.add_argument("--dmrs-symbols", type=int, default=2, help="用于估算 DMRS RE 数，默认 2")
    ap.add_argument("--out-dir", default=None, help="输出目录")
    args = ap.parse_args()

    matlab_out = Path(args.matlab_out)

    packet_csv = matlab_out / "near_blind_packet_results.csv"
    eval_csv = matlab_out / "near_blind_eval_labels.csv"
    channel_csv = matlab_out / "near_blind_channel_context.csv"
    security_csv = matlab_out / "security_context_log.csv"

    packet_df = read_csv(packet_csv)
    eval_df = read_csv(eval_csv)
    channel_df = read_csv(channel_csv)
    security_df = read_csv(security_csv)

    if packet_df is None:
        raise FileNotFoundError(f"找不到 {packet_csv}")

    # 1. 找 sampleId
    if args.sample_id is not None:
        sample_id = int(args.sample_id)
    else:
        sample_id = find_sample_id_by_text(packet_df, args.query_text)
        if sample_id is None:
            print("[WARN] 没有自动找到 BPNv。")
            print("可以先查看 text 样本前几行：")
            cols = [c for c in ["sampleId", "modality", "sourceFileName", "sourceFilePath"] if c in packet_df.columns]
            print(packet_df[packet_df["modality"].astype(str).str.lower() == "text"][cols].head(20).to_string(index=False))
            print("\n然后手动加 --sample-id 运行。")
            return

    print(f"[INFO] 使用 sampleId = {sample_id}")

    # 2. 读取该样本对应行
    packet_row = get_row_by_sample_id(packet_df, sample_id)
    eval_row = get_row_by_sample_id(eval_df, sample_id)
    channel_row = get_row_by_sample_id(channel_df, sample_id)
    security_row = get_row_by_sample_id(security_df, sample_id)

    # 3. 输出目录
    out_dir = Path(args.out_dir) if args.out_dir else matlab_out / "bpnv_parameter_report"
    out_dir.mkdir(parents=True, exist_ok=True)

    # ======================================================
    # 表 1：无线帧 / 调度 / 承载结构参数
    # ======================================================
    num_prb = safe_int(pick(packet_row, "numPrb"), 0)
    num_symbols = safe_int(pick(packet_row, "numOFDMSymbols"), 0)

    total_re = num_prb * num_symbols * 12 if num_prb and num_symbols else None
    dmrs_re = num_prb * args.dmrs_symbols * 12 if num_prb else None
    data_re = total_re - dmrs_re if total_re is not None and dmrs_re is not None else None

    frame_rows = [
        {"参数": "sampleId", "数值": sample_id, "来源字段": "sampleId", "说明": "样本编号"},
        {"参数": "modality", "数值": pick(packet_row, "modality"), "来源字段": "modality", "说明": "业务模态"},
        {"参数": "payloadType", "数值": pick(packet_row, "payloadType"), "来源字段": "payloadType", "说明": "payload 类型"},
        {"参数": "mcs", "数值": pick(packet_row, "mcs"), "来源字段": "mcs", "说明": "调制编码方案索引"},
        {"参数": "numPrb", "数值": num_prb, "来源字段": "numPrb", "说明": "PUSCH 占用 PRB 数"},
        {"参数": "numActiveSubcarriers", "数值": pick(packet_row, "numActiveSubcarriers"), "来源字段": "numActiveSubcarriers", "说明": "活跃子载波数"},
        {"参数": "numOFDMSymbols", "数值": num_symbols, "来源字段": "numOFDMSymbols", "说明": "OFDM 符号数"},
        {"参数": "Total RE", "数值": total_re, "来源字段": "numPrb × numOFDMSymbols × 12", "说明": "总 RE 数"},
        {"参数": "DMRS RE", "数值": dmrs_re, "来源字段": f"numPrb × {args.dmrs_symbols} × 12", "说明": "估算 DMRS RE 数"},
        {"参数": "Data RE", "数值": data_re, "来源字段": "Total RE - DMRS RE", "说明": "估算 Data RE 数"},
        {"参数": "payloadBytes", "数值": pick(packet_row, "payloadBytes"), "来源字段": "payloadBytes", "说明": "进入 PHY 的 payload 字节数"},
        {"参数": "appPlainBytes", "数值": pick(packet_row, "appPlainBytes"), "来源字段": "appPlainBytes", "说明": "应用层加密前明文字节数"},
        {"参数": "appCipherBytes", "数值": pick(packet_row, "appCipherBytes"), "来源字段": "appCipherBytes", "说明": "应用层密文字节数"},
        {"参数": "macPduBytes", "数值": pick(packet_row, "macPduBytes"), "来源字段": "macPduBytes", "说明": "MAC-like PDU 字节数"},
    ]

    df_frame = pd.DataFrame(frame_rows)

    # ======================================================
    # 表 2：真实配置值 vs 近盲估计值
    # ======================================================
    compare_rows = []

    pairs = [
        ("SNR", ["trueSnrDb"], ["estSnrFromBurst"], "burst 信号功率 / 噪声功率估计", False),
        ("Nfft", ["trueNfft"], ["estNfft"], "CP 相关与候选 FFT 搜索", False),
        ("Ncp", ["trueNcp"], ["estNcp"], "CP 相关与候选 CP 搜索", False),
        ("Modulation", ["trueMod"], ["estModName"], "均衡星座点拟合", False),
        ("Start index", ["trueStart"], ["estStart"], "burst 起点 / 同步位置估计", False),
        ("CFO", ["trueCFO"], ["estCFO"], "CP 相关相位差估计", False),
        ("CFO abs", ["trueCFO"], ["cfoAbs"], "CP 相关相位差估计后取绝对值", True),
        ("Flow bursts", ["trueFlowNumBursts"], ["flowNumBurstsEst"], "能量包络多 burst 检测", False),
    ]

    for name, ref_names, est_names, method, abs_ref in pairs:
        ref_key, ref_val = pick_with_key(packet_row, *ref_names)
        est_key, est_val = pick_with_key(packet_row, *est_names)
        add_compare(compare_rows, name, ref_key, ref_val, est_key, est_val, method, abs_ref=abs_ref)

    # 解析是否正确的布尔项
    for name in ["fftOk", "cpOk", "modOk", "ser", "evm", "startErr"]:
        compare_rows.append({
            "参数": name,
            "真实/参考字段": "",
            "真实/参考值": "",
            "估计/解析字段": name,
            "估计/解析值": pick(packet_row, name),
            "误差(估计-真实)": "",
            "绝对误差": "",
            "估计方法": "前端解析质量评价指标"
        })

    df_compare = pd.DataFrame(compare_rows)

    # ======================================================
    # 表 3：CSI / RSRP / CIR 信道观测
    # ======================================================
    ch_source = channel_row if channel_row else packet_row

    channel_fields = [
        ("rsrpLikeFullDb", "整段接收波形的 RSRP-like 接收强度"),
        ("rsrpLikeBurstDb", "有效 burst 区域的 RSRP-like 接收强度"),
        ("noiseFloorLikeDb", "噪声底估计"),
        ("csiLikeMeanGainDb", "CSI-like 平均信道增益"),
        ("csiLikeGainStdDb", "CSI-like 信道增益波动"),
        ("csiLikeFreqSelectivity", "频率选择性"),
        ("csiLikePhaseStd", "信道相位波动"),
        ("csiLikeNoiseEstimate", "基于信道估计的噪声估计"),
        ("cirLikeNumTapsTrue", "真实 CIR tap 数"),
        ("cirLikeRmsDelayTrue", "真实 RMS 时延扩展"),
        ("cirLikeMaxDelayTrue", "真实最大时延"),
        ("cirLikePowerSpreadDbTrue", "真实路径功率扩展"),
        ("cirLikeNumTapsEst", "估计 CIR tap 数"),
        ("cirLikeRmsDelayEst", "估计 RMS 时延扩展"),
        ("cirLikeMaxDelayEst", "估计最大时延"),
        ("nrTdlDelayProfile", "NR TDL 信道模型"),
        ("nrTdlDelaySpread", "TDL 时延扩展配置"),
        ("nrMaxDopplerShift", "最大多普勒频移"),
    ]

    df_channel = pd.DataFrame([
        {
            "参数": field,
            "数值": pick(ch_source, field),
            "说明": desc
        }
        for field, desc in channel_fields
    ])

    # ======================================================
    # 表 4：RRC / MAC / 安全上下文与 payload 可见性
    # ======================================================
    sec_source = security_row if security_row else packet_row

    security_fields = [
        ("appEncEnabled", "是否启用应用层加密"),
        ("appEncMode", "应用层加密模式"),
        ("appKeyId", "应用层密钥 ID，仅用于实验标识"),
        ("appPlainBytes", "应用层明文字节数"),
        ("appCipherBytes", "应用层密文字节数"),
        ("payloadVisibleAtGnbAfterPdcp", "gNB 用户面解密后的 payload 可见性"),
        ("pdcpCountStart", "PDCP-like COUNT 起始值"),
        ("pdcpSnStart", "PDCP-like SN 起始值"),
        ("bearer", "DRB / bearer 抽象编号"),
        ("direction", "方向，0 表示 uplink"),
        ("rrcState", "RRC-like 状态"),
        ("rrcSecurityMode", "RRC-like 安全模式"),
        ("rrcDrbId", "DRB ID"),
        ("rrcQfi", "QoS Flow ID"),
        ("macLcid", "MAC-like LCID"),
        ("macHarqProcessId", "HARQ 进程编号"),
        ("macBsrBucket", "BSR 分桶"),
        ("macSubheaderBytes", "MAC-like 子头长度"),
    ]

    df_security = pd.DataFrame([
        {
            "参数": field,
            "数值": pick(sec_source, field),
            "说明": desc
        }
        for field, desc in security_fields
    ])

    # ======================================================
    # 表 5：BPNv 文本位置说明
    # ======================================================
    text_hex = "42 50 4E 76"
    df_payload = pd.DataFrame([
        {"层级": "应用原文", "示例值": args.query_text, "是否在无线帧字段中直接可见": "否", "说明": "原始文本不直接写入 frame/slot/PRB 字段"},
        {"层级": "明文 payload bytes", "示例值": text_hex, "是否在无线帧字段中直接可见": "加密时不可见", "说明": "BPNv 的 UTF-8/ASCII 字节"},
        {"层级": "应用层密文", "示例值": "由 app 加密产生，当前 CSV 默认记录长度和可见性，不记录完整密文字节", "是否在无线帧字段中直接可见": "否", "说明": "gNB 用户面解密后可得到应用层密文"},
        {"层级": "PDCP-like 用户面密文", "示例值": "位于 Transport Block payload 内", "是否在无线帧字段中直接可见": "否", "说明": "需要 PUSCH 解码和 TB 恢复后才可见"},
        {"层级": "Data RE", "示例值": "调制符号", "是否在无线帧字段中直接可见": "不是文本形式", "说明": "BPNv 经加密、编码、调制后映射到 Data RE"},
        {"层级": "Transport Block", "示例值": pick(packet_row, "payloadBytes"), "是否在无线帧字段中直接可见": "解析后可见", "说明": "Data RE 解调译码后恢复 TB/payload"},
    ])

    # ======================================================
    # 保存结果
    # ======================================================
    csv_paths = {
        "frame": out_dir / f"sample_{sample_id}_frame_structure.csv",
        "compare": out_dir / f"sample_{sample_id}_true_vs_est.csv",
        "channel": out_dir / f"sample_{sample_id}_channel_observation.csv",
        "security": out_dir / f"sample_{sample_id}_security_context.csv",
        "payload": out_dir / f"sample_{sample_id}_bpnv_payload_visibility.csv",
    }

    df_frame.to_csv(csv_paths["frame"], index=False, encoding="utf-8-sig")
    df_compare.to_csv(csv_paths["compare"], index=False, encoding="utf-8-sig")
    df_channel.to_csv(csv_paths["channel"], index=False, encoding="utf-8-sig")
    df_security.to_csv(csv_paths["security"], index=False, encoding="utf-8-sig")
    df_payload.to_csv(csv_paths["payload"], index=False, encoding="utf-8-sig")

    xlsx_path = out_dir / f"sample_{sample_id}_bpnv_parameter_report.xlsx"
    try:
        with pd.ExcelWriter(xlsx_path, engine="openpyxl") as writer:
            df_frame.to_excel(writer, sheet_name="帧结构参数", index=False)
            df_compare.to_excel(writer, sheet_name="真实值_估计值对比", index=False)
            df_channel.to_excel(writer, sheet_name="信道观测", index=False)
            df_security.to_excel(writer, sheet_name="安全上下文", index=False)
            df_payload.to_excel(writer, sheet_name="BPNv位置说明", index=False)
        print(f"[SAVED] {xlsx_path}")
    except Exception as e:
        print(f"[WARN] Excel 保存失败，仅保存 CSV。原因：{e}")

    print("\n========== 帧结构参数 ==========")
    print(df_frame.to_string(index=False))

    print("\n========== 真实值 vs 估计值 ==========")
    print(df_compare.to_string(index=False))

    print("\n========== 信道观测 ==========")
    print(df_channel.to_string(index=False))

    print("\n========== 安全上下文 ==========")
    print(df_security.to_string(index=False))

    print("\n[CSV 输出]")
    for p in csv_paths.values():
        print(p)

    print("\n[DONE]")


if __name__ == "__main__":
    main()