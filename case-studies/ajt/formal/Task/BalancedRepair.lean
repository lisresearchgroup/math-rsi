import Task.PolynomialCharacters

/-! The restricted-coefficient argument of Nagy, Pach and Tomon,
arXiv:2111.13658, Lemmas 2.4 and 2.5, in the homogeneous case. -/

open Finset
open scoped BigOperators

namespace AlonJaegerTarsi.BalancedCover

noncomputable section

variable {I G : Type*} [DecidableEq I] [AddCommGroup G]

def differences (v : I → G) (s : Finset I) : AddMonoidAlgebra ℤ G :=
  ∏ i ∈ s, (1 - AddMonoidAlgebra.single (v i) 1)

theorem represents_of_coeff_ne (v : I → G) (s : Finset I) (g : G)
    (h : (differences v s).coeff g ≠ 0) : ∃ U ⊆ s, (∑ i ∈ U, v i) = g := by
  classical
  by_contra! ha
  apply h
  unfold differences
  simp_rw [sub_eq_add_neg, ← AddMonoidAlgebra.single_neg]
  rw [Finset.prod_one_add]
  simp only [AddMonoidAlgebra.prod_single, prod_const, AddMonoidAlgebra.coeff_sum,
    Finsupp.finsetSum_apply, AddMonoidAlgebra.coeff_single, Finsupp.single_apply]
  exact sum_eq_zero fun u hu => if_neg (ha u (mem_powerset.mp hu))

/-- An essential last difference forces two Boolean subset sums of the other
vectors to differ by that last vector. -/
theorem relation_of_essential (v : I → G) (s : Finset I) (w : I) (hw : w ∈ s)
    (hz : differences v s = 0) (hne : differences v (s.erase w) ≠ 0) :
    ∃ U ⊆ s.erase w, ∃ T ⊆ s.erase w, v w = (∑ i ∈ U, v i) - ∑ i ∈ T, v i := by
  classical
  let Q := differences v (s.erase w)
  obtain ⟨z, hcoef⟩ : ∃ z, Q.coeff z ≠ 0 := by
    by_contra! h
    exact hne (by ext g; exact h g)
  have hzero : Q * (1 - AddMonoidAlgebra.single (v w) 1) = 0 :=
    (prod_erase_mul _ _ hw).trans hz
  have he : Q = Q * AddMonoidAlgebra.single (v w) 1 := by
    simpa [mul_sub, sub_eq_zero] using hzero
  have ht : Q.coeff (z + v w) = Q.coeff z := by
    simpa using congrArg (fun f : AddMonoidAlgebra ℤ G => f.coeff (z + v w)) he
  obtain ⟨U, hU, heU⟩ := represents_of_coeff_ne v (s.erase w) (z + v w) (ht ▸ hcoef)
  obtain ⟨T, hT, heT⟩ := represents_of_coeff_ne v (s.erase w) z hcoef
  exact ⟨U, hU, T, hT, by rw [heU,heT]; abel⟩

variable {K : Type*} [Field K] [Fintype K] [DecidableEq K] [Module K G] [Fintype I]

/-- Every element of a nonempty balanced set is the midpoint of two different
members. In odd characteristic this is the usual balanced-set condition. -/
def Balanced (S : Finset K) : Prop :=
  S.Nonempty ∧ ∀ a ∈ S, ∃ b : K, b ≠ 0 ∧ a+b ∈ S ∧ a-b ∈ S

def combine (v : I → G) (a : I → K) : G := ∑ j, a j • v j

/-- Restricted coefficient representations follow if every coordinate of any
rescaling can be repaired by a difference of two subset sums. -/
theorem represent_by_balanced (v : I → G) (S : Finset K) (hS : Balanced S)
    (repair : ∀ (b : I → K), (∀ j, b j ≠ 0) → ∀ w : I,
      ∃ U ⊆ univ.erase w, ∃ T ⊆ univ.erase w,
        b w • v w = (∑ j ∈ U, b j • v j) - ∑ j ∈ T, b j • v j)
    (a : I → K) : ∃ c : I → K, combine v c = combine v a ∧ ∀ j, c j ∈ S := by
  classical
  let F := univ.filter (fun c : I → K => combine v c = combine v a)
  let good (c : I → K) := univ.filter (fun i => c i ∈ S)
  obtain ⟨c,hc,hmax⟩ := exists_max_image F (fun c => (good c).card)
    (show F.Nonempty from ⟨a,by simp [F]⟩)
  have heq := (mem_filter.mp hc).2
  refine ⟨c,heq,?_⟩
  intro w
  by_contra hw
  obtain ⟨a₀,ha₀⟩ := hS.1
  have hstep (j : I) : ∃ b : K, b ≠ 0 ∧ (c j ∈ S → c j + b ∈ S ∧ c j - b ∈ S) ∧
      (j = w → c j + b ∈ S) := by
    by_cases hj : j = w
    · subst j
      exact ⟨a₀-c w, sub_ne_zero.mpr (fun e => hw (e ▸ ha₀)),
        fun h => (hw h).elim, fun _ => by simpa using ha₀⟩
    · by_cases h : c j ∈ S
      · obtain ⟨b,hb,hp,hm⟩ := hS.2 _ h
        exact ⟨b,hb,fun _ => ⟨hp,hm⟩,fun e => (hj e).elim⟩
      · exact ⟨1,one_ne_zero,fun e => (h e).elim,fun e => (hj e).elim⟩
  choose b hb hkeep hfix using hstep
  obtain ⟨U,hU,T,hT,hrel⟩ := repair b hb w
  let c' (j : I) := c j + (if j=w then b j else 0) -
    (if j∈U then b j else 0) + (if j∈T then b j else 0)
  have kept {j : I} (hj : c j ∈ S) : c' j ∈ S := by
    have hn : j ≠ w := fun e => hw (e ▸ hj)
    obtain ⟨hp,hm⟩ := hkeep j hj
    by_cases hu : j ∈ U <;> by_cases ht : j ∈ T <;> simp [c',hn,hu,ht,hp,hm,hj]
  have hu : w ∉ U := fun h => (mem_erase.mp (hU h)).1 rfl
  have ht : w ∉ T := fun h => (mem_erase.mp (hT h)).1 rfl
  have fixed : c' w ∈ S := by simpa [c',hu,ht] using hfix w rfl
  have hc' : c' ∈ F := by
    apply mem_filter.mpr
    refine ⟨mem_univ _, Eq.trans ?_ heq⟩
    unfold combine
    simp only [c', add_smul, sub_smul, ite_smul, zero_smul, sum_add_distrib, sum_sub_distrib,
      sum_ite_eq', mem_univ, if_true, sum_ite_mem_eq]
    rw [hrel]
    abel
  have hsmall : good c ⊂ good c' := by
    refine Finset.ssubset_iff_subset_ne.mpr ⟨fun j hj => mem_filter.mpr
      ⟨mem_univ _, kept (mem_filter.mp hj).2⟩, ?_⟩
    intro e
    have hj : w ∈ good c' := mem_filter.mpr ⟨mem_univ _,fixed⟩
    exact hw (mem_filter.mp (e ▸ hj : w ∈ good c)).2
  exact (Nat.not_lt_of_ge (hmax c' hc')) (card_lt_card hsmall)

end
end AlonJaegerTarsi.BalancedCover
