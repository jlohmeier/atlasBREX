# atlasBREX
**atlasBREX: Automated averaged template-derived brain extraction in animal MRI**

![alt text](http://www.blog.jlohmeier.de/wp-content/uploads/2017/03/animation_34.gif "Sample")
###### *Developmental (24 months) T2-weighted rhesus macaque from UNC-Wisconsin Neurodevelopment Rhesus Database (The UNC-Wisconsin Rhesus Macaque Neurodevelopment Database: A Structural MRI and DTI Database of Early Postnatal Development)*

Due to optimization for the human brain, most common skullstripping/brain-extraction methods, such as AFNI's [3dSkullStrip](https://afni.nimh.nih.gov/pub/dist/doc/program_help/3dSkullStrip.html) or FSL's [BET](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/BET),  achieve insufficient results for non-human brains, which then require further manual intervention. Making use of the available brain-extraction from a template/atlas, this approach implements brain-extraction through reversal (rigid- and non-rigid) deformation of a template-derived mask.

- time-saving and straightforward (with various optional parameters for further optimization)
- multi-step registration (2- or 3-step) for improved registration to low resolution datasets
- robust FSL (FLIRT, FNIRT) or ANTs (SyN) registration frameworks
- compatible with T1-/T2-weighted datasets

## Requirements:
- [FSL (FMRIB Software Library)](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- Bash >= 4 (echo $SHELL)

*Optional:*
- [AFNI (Analysis of Functional NeuroImages)](https://afni.nimh.nih.gov/afni/): 3dAutomask, 3dUnifize
- [ANTs (Advanced Normalization Tools)](https://github.com/stnava/ANTs): antsRegistration, antsApplyTransforms, N4BiasFieldCorrection, ImageMath and antsRegistrationSyN

Last tested with ANTs v2.3.4, AFNI_20.0.18 ('Galba') and FSL v6.0.3.

## Last changes:
v1.5 - non-linear registration between skullstripped template and target volume for low-resolution volumes.

v1.2 - SyN makes use of an initial transform.

v1.1 - Fixed an error regarding the NIFTI header.

## Usage:

```
bash atlasBREX.sh -b <input> -nb <input> -h <input> -f <input>
(no multi-line commands)
```

#### Practical example:

- b_template_brain.nii.gz (brain-extracted template)
- nb_template.nii.gz (whole-head template)
- sj_170308_1.nii.gz (subject #1)
- sj_170308_2.nii.gz (subject #2)
- sj_170308_3.nii.gz (subject #3)

Copy all gzipped (.nii.gz) NIFTI volumes and *atlasBREX.sh* into a **common** folder. There should be no directory or file containing *'orig'*, *'temp'* or *'_.nii.gz'* in this folder.

**1. Step**: Brief interactive pilot run (approx. 2-3 minutes) using the `-f n` flag to determine a reasonable fractional intensity value. AtlasBREX will propose 3 images for selection (choose the option with least extracranial tissue) during this pilot-run. 
- use the `-nrm 1` flag for T1w intensity normalization, where AFNI is available (improves provisional brain-extraction and registration accuracy)
- if brain regions appear clipped using FLIRT/FNIRT, try to adjust the fractional intensity or reduce the FOV using `robustfov` (FSL) to improve preliminary brain-extraction. 
- if available, try `-reg 2` for the ANTs registration framework

```
bash atlasBREX.sh -b b_template_brain.nii.gz -nb nb_template.nii.gz -h sj_170308_1.nii.gz -f n
```

**2. Step**: Run atlasBREX (with non-linear deformation) on all subjects in an automated and unattended manner:

```
for file in *'sj_'*'.nii.gz'*
  do
    bash atlasBREX.sh -b b_template_brain.nii.gz -nb nb_template.nii.gz -h $file -reg 1 -w 10,10,10 -msk a,0,0 -f 0.2
  wait
done
```

- Sample dataset: https://github.com/jlohmeier/atlasBREX/tree/master/demonstration
- Example helper script: https://github.com/jlohmeier/atlasBREX/blob/master/example.sh
- [Visual (hands-on) walkthrough w/ rhesus macaque](http://www.blog.jlohmeier.de/wp-content/uploads/2017/03/visual_walkthrough.jpg) (*public sample data from Allen Institute for Brain Science*)

## Arguments:

**Compulsory arguments:**

    -b          brain-extracted atlas or template
    -nb         whole-head (non-brain) atlas or template
    -h          target 3D volume
    -f          fractional intensity threshold [1 > n > 0] for provisional (BET) brain-extraction (e.g. -f 0.2).
                interactive pilot: [-f n] proposes 3 default thresholds for user selection. 
                for multi-step registration, different values for high-res, 
                low-res and native volumes can be entered (e.g. -f 0.2,0.5,0.8)

**Optional arguments:**

    -l          low-resolution 3D volume (3-step registration)
    -n          (functional) 3D/4D volume  (2-/3-step registration)
    -t/-tmp     disable removal [1] of temporary files (default: 0) 
    -w/-wrp     define FNIRT (FSL) warp-resolution (e.g. -wrp 10,10,10),
                for SyN (ANTs) enter warp [-wrp 1] flag (e.g. -wrp 1 -reg 2)
    -r/-reg     FNIRT w/ bending- [-reg 0] or membrane-energy regularization [-reg 1] 
                ANTs/SyN w/ [-reg 2] or w/o [-reg 3] additional N4BiasFieldCorrection (def: 1)
    -nrm        provisional intensity normalization w/ T1 [-nrm 1] or T2 [-nrm 2] (req: AFNI)
                (recommended for low-resolution volumes)
    -lr         optimized parameter settings for low-resolution volumes:
                [1] non-linear registration between whole-head template and target volume with mask
                [2] non-linear registration based on skullstripped template and target volume (def: 0)
    -msk        mask binarization threshold (in %) for fslmaths 
                w/ optional erosion and dilation (e.g. -msk b,10,0,0) (def: b,0.5,0,0)
                [-msk b,[100 < n > 0] for threshold, [0-9] for n-times erosion,
                [0-9] for n-times dilation] or 3dAutomask (e.g. -msk a,0,0, req: AFNI) 
                [-msk a,[0-9] for n-times erosion,[0-9] for n-times dilation]
    -vox        provisional voxel-size adjustment [-vox 1] (def: 0)
    -dil        n-times dilation of the brain-extraction from linear registration 
                prior to non-linear registration (e.g. -dil 4)

## Notes:
- use `-help`/`--help` for further details.
- see *log.txt* for a summary after running the script.
- use `-f n` during the test-run to determine a suitable fractional intensity threshold. atlasBREX will propose 3 brain-extractions and lets you choose at the beginning of the procedure.
- use `-nrm` flag for intensity normalization (AFNI required) for low-resolution volumes (both T2w and T1w) and (useful for) T1w scans.
- use `-dil` flag in case of registration failures during non-linear registration. (n >= 4 as recommended starting point)
- each (non-template) input volume will be brain-extracted, appended with a "_brain.nii.gz" or "_brain_lin.nii.gz" suffix.
- adjust warp-resolution if you encounter issues with memory (e.g. std::bad_alloc).
- non-linear transformation matrix and warp file are preserved (to reduce total computation time for brain-extraction of multiple downstream input volumes).
- if result appears miswarped, review your volumes for inconsistencies regarding q- and s-form within NIFTI headers.
- number of threads can be set within the script for parallel computing (ANTS).
- make sure you're using Git LFS when downloading the sample files: https://developer.lsst.io/git/git-lfs.html

### Links:
- FSL: http://fsl.fmrib.ox.ac.uk
- AFNI: https://afni.nimh.nih.gov/afni/
- ANTs: https://github.com/stnava/ANTs
- ABSORB: https://www.nitrc.org/projects/absorb

### Open source: BSD-3-Clause
If you use this application or part of its source code, please cite *atlasBREX* with a reference to this Github page.

**atlasBREX: Automated template-derived brain extraction in animal MRI**<br/>
Scientific Reports, volume 9, Article number: 12219 (2019)<br/>
DOI: 10.1038/s41598-019-48489-3

**Integrated in Macapype:**
https://macatools.github.io/macapype/generated/macapype.nodes.extract_brain.AtlasBREX.html

**Selected preclinical studies that have used atlasBREX:**

Lohmeier, J., Silva, R., Tietze, A. et al. Fibrin-targeting molecular MRI in inflammatory CNS disorders. Eur J Nucl Med Mol Imaging (2022). 
DOI: 10.1007/s00259-022-05807-8

Adam Messinger, Nikoloz Sirmpilatze, Katja Heuer, Kep Kee Loh, Rogier Mars, et al.. A collaborative resource platform for non-human primate neuroimaging. NeuroImage, Elsevier, 2021, 226, pp.117519.
DOI: 10.1016/j.neuroimage.2020.117519.hal-03167240

Ren, B.X., Huen, I., Wu, Z.J. et al. Early postnatal irradiation‐induced age‐dependent changes in adult mouse brain: MRI based characterization. BMC Neurosci 22, 28 (2021).
DOI: 10.1186/s12868-021-00635-2

Pamela Garcia-Saldivar, Arun Garimella, Eduardo A. Garza-Villarreal, Felipe A. Mendez, Luis Concha, Hugo Merchant,
PREEMACS: Pipeline for preprocessing and extraction of the macaque brain surface, NeuroImage, Volume 227, 2021, 117671, ISSN 1053-8119.
DOI: 10.1016/j.neuroimage.2020.117671
