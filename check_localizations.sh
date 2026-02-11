#!/bin/bash

echo "检查奖杯本地化完整性..."
echo ""

# 提取所有奖杯ID
trophy_ids=$(grep 'Trophy(id: "' "Tikkuu Focus/Models/Trophy.swift" | sed 's/.*Trophy(id: "\([^"]*\)".*/\1/' | sort)

missing_zh=0
missing_en=0

echo "检查中文本地化..."
for id in $trophy_ids; do
    if ! grep -q "\"trophy.$id.title\"" "Tikkuu Focus/Resources/zh-Hans.lproj/Localizable.strings"; then
        echo "❌ 缺少中文: trophy.$id.title"
        ((missing_zh++))
    fi
    if ! grep -q "\"trophy.$id.description\"" "Tikkuu Focus/Resources/zh-Hans.lproj/Localizable.strings"; then
        echo "❌ 缺少中文: trophy.$id.description"
        ((missing_zh++))
    fi
done

echo ""
echo "检查英文本地化..."
for id in $trophy_ids; do
    if ! grep -q "\"trophy.$id.title\"" "Tikkuu Focus/Resources/en.lproj/Localizable.strings"; then
        echo "❌ 缺少英文: trophy.$id.title"
        ((missing_en++))
    fi
    if ! grep -q "\"trophy.$id.description\"" "Tikkuu Focus/Resources/en.lproj/Localizable.strings"; then
        echo "❌ 缺少英文: trophy.$id.description"
        ((missing_en++))
    fi
done

echo ""
echo "=========================================="
echo "总奖杯数: $(echo "$trophy_ids" | wc -l | tr -d ' ')"
echo "缺少中文本地化: $missing_zh"
echo "缺少英文本地化: $missing_en"
echo ""

if [ $missing_zh -eq 0 ] && [ $missing_en -eq 0 ]; then
    echo "✅ 所有奖杯都有完整的本地化！"
else
    echo "⚠️  有缺失的本地化需要补充"
fi
