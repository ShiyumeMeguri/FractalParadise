#ifndef FRACTAL_FUNCTION_INCLUDED
#define FRACTAL_FUNCTION_INCLUDED

// 计算复数 z 的 p 次幂 (z^p)
float2 cx_pow(float2 z, float2 p)
{
    // 处理 z = 0 的情况, 避免 log(0) 导致结果为 NaN
    if (z.x == 0.0 && z.y == 0.0) return float2(0, 0);

    // 公式: z^p = exp(p * log(z))
    // 其中 log(z) = log(|z|) + i*arg(z)
    // log(|z|) = 0.5 * log(z.x*z.x + z.y*z.y)
    // arg(z) = atan2(z.y, z.x)
    float log_r = 0.5 * log(dot(z, z));
    float theta = atan2(z.y, z.x);

    // 计算 p * log(z)
    // (p.x + i*p.y) * (log_r + i*theta) = (p.x*log_r - p.y*theta) + i*(p.x*theta + p.y*log_r)
    float real_part = p.x * log_r - p.y * theta;
    float imag_part = p.x * theta + p.y * log_r;

    // 计算 exp(real_part + i*imag_part)
    // exp(x + iy) = exp(x) * (cos(y) + i*sin(y))
    float r = exp(real_part);
    return float2(r * cos(imag_part), r * sin(imag_part));
}

// (1) 定义复数运算工具函数
float2 cx_mul(float2 a, float2 b)
{
    return float2(
        a.x*b.x - a.y*b.y,
        a.x*b.y + a.y*b.x
    );
}

float2 cx_sqr(float2 a)
{
    float x2 = a.x*a.x;
    float y2 = a.y*a.y;
    float xy = a.x*a.y;
    return float2(x2 - y2, xy + xy);
}

float2 cx_cube(float2 a)
{
    float x2 = a.x*a.x;
    float y2 = a.y*a.y;
    float d  = x2 - y2;
    return float2(
        a.x*(d - y2 - y2),
        a.y*(x2 + x2 + d)
    );
}

float2 cx_div(float2 a, float2 b)
{
    float denom = 1.0 / (b.x*b.x + b.y*b.y);
    float2 numerator = float2(
        a.x*b.x + a.y*b.y,
        a.y*b.x - a.x*b.y
    );
    return numerator * denom;
}

// (2) 定义所有分形函数
float2 mandelbrot(float2 z, float2 c)
{
    float2 p = float2(_PowerReal, _PowerImag);

    // 当次幂为 (2, 0) 时，使用效率更高的平方函数
    if (p.x == 2.0 && p.y == 0.0)
    {
        return cx_sqr(z) + c;
    }
    
    // 其他情况下，使用通用的复数次幂函数
    return cx_pow(z, p) + c;
}

// --- 代码修正 ---
float2 burning_ship(float2 z, float2 c)
{
    // Burning Ship 的核心在于对 z 的分量取绝对值
    z = abs(z);
    
    float2 p = float2(_PowerReal, _PowerImag);

    // 当次幂为 (2, 0) 时，为原版 Burning Ship
    if (p.x == 2.0 && p.y == 0.0)
    {
        return cx_sqr(z) + c;
    }
    
    // 其他情况下，对取绝对值后的 z 进行复数次幂计算
    return cx_pow(z, p) + c;
}

// --- 代码修正 ---
float2 feather(float2 z, float2 c)
{
    // 原公式: z -> (z^3 / (1 + z*z)) + c
    // 将其推广为 z -> (z^p / (1 + z*z)) + c
    // 保留分母中的 z*z 以维持其基本形态
    float2 one = float2(1.0, 0.0);
    float2 zSquared = z * z;
    float2 p = float2(_PowerReal, _PowerImag);

    // 当次幂为 (3, 0) 时，使用效率更高的立方函数
    if (p.x == 3.0 && p.y == 0.0)
    {
         return cx_div(cx_cube(z), (one + zSquared)) + c;
    }

    return cx_div(cx_pow(z, p), (one + zSquared)) + c;
}

// --- 未修改 ---
// Sfx, Henon, Duffing, Ikeda, Chirikov 具有不同的数学结构，
// 它们不是 z -> z^p + c 的直接变体，因此不应用复数次幂替换。
float2 sfx(float2 z, float2 c)
{
    float d = dot(z,z);
    float2 cc2 = float2(c.x*c.x - c.y*c.y, 2*c.x*c.y);
    return z*d - cx_mul(z, cc2);
}

float2 henon(float2 z, float2 c)
{
    return float2(
        1.0 - c.x*z.x*z.x + z.y,
        c.y * z.x
    );
}

float2 duffing(float2 z, float2 c)
{
    return float2(
        z.y,
        -c.y*z.x + c.x*z.y - z.y*z.y*z.y
    );
}

float2 ikeda(float2 z, float2 c)
{
    float t = 0.4 - 6.0 / (1.0 + dot(z,z));
    float st = sin(t);
    float ct = cos(t);
    return float2(
        1.0 + c.x*(z.x*ct - z.y*st),
        c.y*(z.x*st + z.y*ct)
    );
}

float2 chirikov(float2 z, float2 c)
{
    z.y += c.y * sin(z.x);
    z.x += c.x * z.y;
    return z;
}

// (3) 统一接口
float2 applySelectedFractal(int fractalType, float2 z, float2 c)
{
    switch (fractalType)
    {
        case 0:  return mandelbrot(z, c);
        case 1:  return burning_ship(z, c);
        case 2:  return feather(z, c);
        case 3:  return sfx(z, c);
        case 4:  return henon(z, c);
        case 5:  return duffing(z, c);
        case 6:  return ikeda(z, c);
        case 7:  return chirikov(z, c);
        default: return mandelbrot(z, c); 
    }
}

#endif // FRACTAL_FUNCTION_INCLUDED