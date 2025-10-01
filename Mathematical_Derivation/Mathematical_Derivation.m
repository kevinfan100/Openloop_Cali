clear; clc;
%% 定義符號變量
syms a1 a2 b w h c s Q real

%% 定義誤差
R = -h*s*w*a1 + h*c*a2 - (b + h*c*w^2);
I = h*c*w*a1 + h*s*a2 - h*s*w^2;

%% 成本函數（單個頻率點，加入權重Q）
J = Q*(R^2 + I^2);

%% 自動求偏導並簡化
dJ_da1 = simplify(diff(J, a1));
dJ_da2 = simplify(diff(J, a2));
dJ_db = simplify(diff(J, b));

assume(c^2 + s^2 == 1)
dJ_da1 = simplify(dJ_da1); 
dJ_da2 = simplify(dJ_da2);
dJ_db = simplify(dJ_db);

%% 顯示結果
fprintf('偏導數結果:\n\n')

fprintf('∂J/∂a1 = ')
disp(simplify(expand(dJ_da1)))

fprintf('∂J/∂a2 = ')
disp(simplify(expand(dJ_da2)))

fprintf('∂J/∂b = ')
disp(simplify(expand(dJ_db)))

%% 收集係數
fprintf('\n線性形式（收集係數）:\n\n')

eq1 = collect(dJ_da1, [a1, a2, b]);
eq2 = collect(dJ_da2, [a1, a2, b]);
eq3 = collect(dJ_db, [a1, a2, b]);

fprintf('方程1: ')
disp(eq1)

fprintf('方程2: ')
disp(eq2)

fprintf('方程3: ')
disp(eq3)

%% 生成 LaTeX 代碼（可直接用於論文）
% fprintf('\nLaTeX 格式:\n')
% fprintf('方程1: %s\n', latex(eq1))
% fprintf('方程2: %s\n', latex(eq2))
% fprintf('方程3: %s\n', latex(eq3))

