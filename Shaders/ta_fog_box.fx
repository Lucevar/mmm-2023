static const float NUM_FOG_VOLUMES = 2;

// lua variables
float fogCenters[NUM_FOG_VOLUMES][3];
float fogRadi[NUM_FOG_VOLUMES][3];
float fogColors[NUM_FOG_VOLUMES][3];
float fogDensities[NUM_FOG_VOLUMES];

float3 eyepos;
float4x4 mview;
float4x4 mproj;

texture lastshader;
texture depthframe;

sampler s0 = sampler_state { texture = <lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s2 = sampler_state { texture = <depthframe>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; };

float4 sample0(sampler2D s, float2 t) {
    return tex2Dlod(s, float4(t, 0, 0));
}

float3 toWorld(float2 tex) {
    float3 v = float3(mview[0][2], mview[1][2], mview[2][2]);
    v += (+1/mproj[0][0] * (2*tex.x-1)).xxx * float3(mview[0][0], mview[1][0], mview[2][0]);
    v += (-1/mproj[1][1] * (2*tex.y-1)).xxx * float3(mview[0][1], mview[1][1], mview[2][1]);
    return v;
}

// -------------------------------------------------------------- //

//
// https://www.shadertoy.com/view/Ml3GR8
//
float boxDensity(float3 wpos, float3 wdir, float3 p, float3 r, float dbuffer) {
    float3 d = wdir;
    float3 o = wpos - p;

    // ray-box intersection in box space
    float3 m = 1.0/d;
    float3 n = m*o;
    float3 k = abs(m)*r;
    float3 ta = -n - k;
    float3 tb = -n + k;
    float tN = max(max(ta.x, ta.y), ta.z);
    float tF = min(min(tb.x, tb.y), tb.z);
    if (tN > tF || tF < 0.0) return 0.0;

    // not visible (behind camera or behind dbuffer)
    if (tF < 0.0 || tN > dbuffer) return 0.0;

    // clip integration segment from camera to dbuffer
    tN = max(tN, 0.0);
    tF = min(tF, dbuffer);

    // move ray to the intersection point
    o += tN*d; tF=tF-tN; tN=0.0;

    // density calculation. density is of the form
    //
    // d(x,y,z) = [1-(x/rx)^2] * [1-(y/ry)^2] * [1-(z/rz)^2];
    //
    // this can be analytically integrable (it's a degree 6 polynomial):

    float3 a = 1.0-(o*o)/(r*r);
    float3 b = -2.0*(o*d)/(r*r);
    float3 c = -(d*d)/(r*r);

    float t1 = tF;
    float t2 = t1*t1;
    float t3 = t2*t1;
    float t4 = t2*t2;
    float t5 = t2*t3;
    float t6 = t3*t3;
    float t7 = t3*t4;

    float f = (t1/1.0) * (a.x*a.y*a.z)
            + (t2/2.0) * (a.x*a.y*b.z + a.x*b.y*a.z + b.x*a.y*a.z)
            + (t3/3.0) * (a.x*a.y*c.z + a.x*b.y*b.z + a.x*c.y*a.z + b.x*a.y*b.z + b.x*b.y*a.z + c.x*a.y*a.z)
            + (t4/4.0) * (a.x*b.y*c.z + a.x*c.y*b.z + b.x*a.y*c.z + b.x*b.y*b.z + b.x*c.y*a.z + c.x*a.y*b.z + c.x*b.y*a.z)
            + (t5/5.0) * (a.x*c.y*c.z + b.x*b.y*c.z + b.x*c.y*b.z + c.x*a.y*c.z + c.x*b.y*b.z + c.x*c.y*a.z)
            + (t6/6.0) * (b.x*c.y*c.z + c.x*b.y*c.z + c.x*c.y*b.z)
            + (t7/7.0) * (c.x*c.y*c.z);

    return f;
}

// -------------------------------------------------------------- //

// Ordered dithering matrix
static const float DITHERING[4][4] = {
    0.001176, 0.001961, -0.001176, -0.001699,
    -0.000654, -0.000915, 0.000392, 0.000131,
    -0.000131, -0.001961, 0.000654, 0.000915,
    0.001699, 0.001438, -0.000392, -0.001438
};

float4 draw(float2 tex : TEXCOORD, float2 vpos : VPOS) : COLOR0 {
    float3 color = tex2D(s0, tex);
    float depth = sample0(s2, tex);

    float3 pos = eyepos;
    float3 dir = toWorld(tex);

    // gamma -> linear
    color = pow(color, 2.2);

    // draw fog volumes
    for (int i = 0; i < NUM_FOG_VOLUMES; i++) {
        float3 center = float3(fogCenters[i]);
        float3 radius = float3(fogRadi[i]);

        float density = boxDensity(pos, dir, center, radius, depth);
        if (density > 0.0) {
            // apply lua config
            float fogScalar = 1.0 / sqrt(dot(radius, radius));
            density = density * fogScalar * fogDensities[i];

            // do the fog stuff
            float3 fogColor = float3(fogColors[i]);
            color = lerp(fogColor * fogColor, color, exp(-0.5 * density));
        }
    }

    // linear -> gamma
    color = pow(color, 1/2.2);

    // dithering!
    float dithering = DITHERING[vpos.x % 4][vpos.y % 4];
    color += dithering;

    return float4(color, 1.0);
}

technique T0<string MGEinterface = "MGE XE 0"; string category = "scene";> {
    pass { PixelShader = compile ps_3_0 draw(); }
}
