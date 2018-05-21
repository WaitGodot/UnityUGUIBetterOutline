using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

[ExecuteInEditMode]
public class Outline : BaseMeshEffect
{
    Text text;

    [Range(1, 10)]
    public float OutlineWidth = 1;
    [Range(1,10)]
    public int OutlineSoltness = 5;
    public Color32 OutlineColor = new Color32(0,0,0,255);

    protected override void Start()
    {
        text = GetComponent<Text>();
        if (text)
        {
            text.material = new UnityEngine.Material(Shader.Find("Unlit/outline"));
        }
        UpdateMaterail();
    }

    protected void UpdateMaterail()
    {
        if (text == null || text.material == null)
        {
            return;
        }

        var mat = text.material;
        float w = OutlineWidth * text.fontSize / 24.0f;
        w = w < 1 ? 1 : w;
        w = w > 10 ? 10 : w;
        mat.SetFloat("_OutlineWidth", w);// * text.fontSize / 24.0f * 2);
        mat.SetInt("_OutlineSoftness", OutlineSoltness);
        mat.SetColor("_OutlineColor", OutlineColor);
    }

#if UNITY_EDITOR
    float ow = 0;
    float os = 0;
    Color32 oc = new Color32(0, 0, 0, 0);
    protected void Update()
    {
        if (ow != OutlineWidth ||
            os != OutlineSoltness ||
            oc.Equals(OutlineColor))
        {
            UpdateMaterail();
        }
        ow = OutlineWidth;
        os = OutlineSoltness;
        oc = OutlineColor;
    }
#endif

    public override void ModifyMesh(VertexHelper vh)
    {
        if (!IsActive())
            return;
        var verts = new List<UIVertex>();
        vh.GetUIVertexStream(verts);

        UIVertex vt;
        float s = 0.1f;
        for (int i = 0; i < verts.Count / 6; ++i)
        {
            int j = i * 6;
            Vector2 uv1 = Vector2.zero, uv2 = Vector2.zero;

            Vector2 uv11 = verts[j].uv0;
            Vector2 uv21 = verts[j + 2].uv0;
            Vector3 p1 = verts[j].position;
            Vector3 p2 = verts[j + 2].position;

            uv1.x = Mathf.Min(uv11.x, uv21.x);
            uv1.y = Mathf.Min(uv11.y, uv21.y);
            uv2.x = Mathf.Max(uv11.x, uv21.x);
            uv2.y = Mathf.Max(uv11.y, uv21.y);

            float uvw_x = uv2.x - uv1.x;
            float uvw_y = uv2.y - uv1.y;
            float pw_x = Mathf.Abs(p1.x - p2.x);
            float pw_y = Mathf.Abs(p1.y - p2.y);

            for (int k = 0; k < 6; k ++)
            {
                vt = verts[j + k];
                switch(k)
                {
                    case 0:
                    case 5:
                        vt.position.x -= pw_x * s;
                        vt.position.y += pw_y * s;
                        break;
                    case 1:
                        vt.position.x += pw_x * s;
                        vt.position.y += pw_y * s;
                        break;
                    case 2:
                    case 3:
                        vt.position.x += pw_x * s;
                        vt.position.y -= pw_y * s;
                        break;
                    case 4:
                        vt.position.x -= pw_x * s;
                        vt.position.y -= pw_y * s;
                        break;
                }  

                if (vt.uv0.x == uv2.x)
                {
                    vt.uv0.x += uvw_x * s;
                }else
                {
                    vt.uv0.x -= uvw_x * s;
                }

                if (vt.uv0.y == uv2.y)
                {
                    vt.uv0.y += uvw_y * s;
                }
                else
                {
                    vt.uv0.y -= uvw_y * s;
                }
                
                vt.uv1 = uv1;
                vt.uv2 = uv2;

                verts[j + k] = vt;
            }
        }
        vh.Clear();
        vh.AddUIVertexTriangleStream(verts);
    }
}
