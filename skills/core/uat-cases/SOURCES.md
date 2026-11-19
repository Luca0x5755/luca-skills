# 設計依據：uat-cases 與 browser-evidence

給人讀的出處，不是技能指令。這兩個驗收技能共用一套依據，放在上游的 uat-cases。

- [Kubernetes conformance tests](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/conformance-tests.md) 與 [web-platform-tests](https://web-platform-tests.org/) — 穩定測試編號的業界先例：測試變成第三方消費的合約時，ID 才需要凍結——凍結編號紀律的同構物。
- IEEE 829（測試案例規格欄位：輸入、預期輸出、前置條件缺一不可，否則只是導覽）與 ISTQB 七原則＋黑箱技法（窮舉不可能，測試是抽樣——負向案例紀律的依據）。
- [obra/superpowers](https://github.com/obra/superpowers) — verification-before-completion 的證據語言紀律（沒有新鮮證據不准聲稱通過；should／probably 是紅旗）。
- [ooiyeefei/ccc](https://github.com/ooiyeefei/ccc) — 生態圈最接近的 UAT skill 對照組；continue-on-failure 與 console 錯誤擷取的實務依據。
- Barr et al.、[The Oracle Problem in Software Testing: A Survey](https://earlbarr.com/publications/testoracles.pdf)（IEEE TSE 2015）— 期望結果必須執行前寫死且具體到可判；弱 oracle 默默封頂測試能偵測的東西。
