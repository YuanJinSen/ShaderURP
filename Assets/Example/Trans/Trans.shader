Shader "Unlit/Trans"
{
    Properties
    {
        _Translate("Translate(xyz)", Vector) = (0, 0, 0, 0)
        _Scale("Scale(xyz)Global(w)", Vector) = (1, 1, 1, 1)
        _Rotate("Rotate(xyz)", Vector) = (0, 0, 0, 0)
        [Header(View)]
        _ViewPosition("View Position", Vector) = (0, 0, 0, 0)
        _ViewTarget("View Target", Vector) = (0, 0, 0, 0)
        [Header(Camera)]
        _CameraParam("size(x)near(y)far(z)ratio(w)", Vector) = (0,0,0,1.777)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 positionOS : POSITION;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _Translate;
            float4 _Scale;
            float4 _Rotate;
            float4 _ViewPosition;
            float4 _ViewTarget;
            float4 _CameraParam;
            CBUFFER_END

            v2f vert (a2v v)
            {
                v2f o = (v2f)0;
                //平移矩阵
                float4x4 T = float4x4(
                    1, 0, 0, _Translate.x,
                    0, 1, 0, _Translate.y,
                    0, 0, 1, _Translate.z,
                    0, 0, 0, _Translate.w);
                v.positionOS = mul(T, v.positionOS);
                //缩放矩阵
                float4x4 S = float4x4(
                    _Scale.x*_Scale.w, 0, 0, 0,
                    0, _Scale.y*_Scale.w, 0, 0,
                    0, 0, _Scale.z*_Scale.w, 0,
                    0, 0, 0, 1);
                v.positionOS = mul(S, v.positionOS);
                //旋转矩阵
                _Rotate.xyz = _Rotate.xyz * 3.1415926 / 180;
                float4x4 R1 = float4x4(
                    1,0,0,0,
                    0,cos(_Rotate.x),sin(_Rotate.x),0,
                    0,-sin(_Rotate.x),cos(_Rotate.x),0,
                    0,0,0,1
                );
                float4x4 R2 = float4x4(
                    cos(_Rotate.y), 0, sin(_Rotate.y), 0,
                    0, 1, 0, 0,
                    -sin(_Rotate.y), 0, cos(_Rotate.y), 0,
                    0, 0, 0, 1
                );
                float4x4 R3 = float4x4(
                    cos(_Rotate.z), sin(_Rotate.z), 0, 0,
                    -sin(_Rotate.z), cos(_Rotate.z), 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                );
                v.positionOS = mul(R1, v.positionOS);
                v.positionOS = mul(R3, v.positionOS);
                v.positionOS = mul(R2, v.positionOS);

                //观察空间矩阵
                //P_view = [W_view] * P_world
                //P_view = [V_world]^-1 * P_world
                //P_view = [V_world]^T * P_world
                float3 ViewZ = normalize(_ViewPosition.xyz - _ViewTarget.xyz);
                float3 ViewY = float3(0, 1, 0);
                float3 ViewX = normalize(cross(ViewY, ViewZ));
                ViewY = normalize(cross(ViewZ, ViewX));
                float4x4 M_viewRot = float4x4(
                    ViewX.x, ViewY.x, ViewZ.x, 0,
                    ViewX.y, ViewY.y, ViewZ.y, 0,
                    ViewX.z, ViewY.z, ViewZ.z, 0,
                    0, 0, 0, 1
                );
                float4x4 M_viewTran = float4x4(
                    1, 0, 0, -_ViewPosition.x,
                    0, 1, 0, -_ViewPosition.y,
                    0, 0, 1, -_ViewPosition.z,
                    0, 0, 0, 1
                );
                float4x4 M_view = mul(M_viewRot, M_viewTran);
                //模型空间->世界空间
                float3 world = TransformObjectToWorld(v.positionOS);
                //世界空间->观察空间
                float3 view = mul(M_view, float4(world.xyz, 1));

                //构建相机参数
                float h = _CameraParam.x * 2;
                float r = _CameraParam.w;
                float w = h * r;
                float n = _CameraParam.y;
                float f = _CameraParam.z;
                //正交矩阵
                //P_clip = [V_clip] * P_view;
                //OpenGL
                /*
                float4x4 M_clipOrth = float4x4(
                    2/w, 0, 0, 0,
                    0, 2/h, 0, 0,
                    0, 0, 2/(n-f), (n+f)/(n-f),
                    0, 0, 0, 1
                );
                */
                //DX11
                float4x4 M_clipOrth = float4x4(
                    2/w, 0, 0, 0,
                    0, -2/h, 0, 0,
                    0, 0, 1/(f-n), f/(f-n),
                    0, 0, 0, 1
                );

                //观察空间-正交矩阵->裁切空间
                //o.positionCS = mul(M_clipOrth, float4(view, 1));

                //透视相机投影矩阵
                //OpenGL
                /*
                float4x4 M_clipPerspective = float4x4(
                    2*n/w,0,0,0,
                    0,2*n/h,0,0,
                    0,0,(n+f)/(n-f),2*n*f/(n-f),
                    0,0,-1,0
                );
                */
                //DX11
                float4x4 M_clipPerspective = float4x4(
                    2*n/w,0,0,0,
                    0,-2*n/h,0,0,
                    0,0,n/(f-n),n*f/(f-n),
                    0,0,-1,0
                );
                o.positionCS = mul(M_clipPerspective, float4(view, 1));

                //o.positionCS = TransformWViewToHClip(view);
                //o.positionCS = TransformObjectToHClip(v.positionOS);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDHLSL
        }
    }
}
